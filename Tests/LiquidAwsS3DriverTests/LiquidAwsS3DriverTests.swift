import XCTest
@testable import LiquidAwsS3Driver

final class LiquidAwsS3DriverTests: XCTestCase {
    
    static var storages: FileStorages!

    static var dotenv: [String: String] = {
        let projectRoot = "/" + #file.split(separator: "/").dropLast(3).joined(separator: "/")
        let filePath = projectRoot + "/.env.testing"
        guard let file = try? String(contentsOf: URL(fileURLWithPath: filePath)) else {
            fatalError("Missing `.env.testing` file")
        }
        var dotenv: [String: String] = [:]
        for line in file.components(separatedBy: "\n") {
            let parts = line.components(separatedBy: "=")
            guard
                let key = parts.first?.replacingOccurrences(of: "\"", with: ""),
                let value = parts.last?.replacingOccurrences(of: "\"", with: "")
            else {
                continue
            }
            dotenv[key] = value
        }
        return dotenv
    }()
    
    override class func setUp() {
        super.setUp()

        guard let bucketValue = dotenv["BUCKET"] else {
            fatalError("Missing BUCKET env variable")
        }
        guard let regionValue = dotenv["REGION"] else {
            fatalError("Missing REGION env variable")
        }
        let endpoint = dotenv["ENDPOINT"]
        let region = Region(rawValue: regionValue)
        let bucket = S3.Bucket(name: bucketValue)
        guard bucket.hasValidName() else {
            fatalError("Invalid BUCKET name")
        }

        let pool = NIOThreadPool(numberOfThreads: 1)
        pool.start()
        let fileio = NonBlockingFileIO(threadPool: pool)
        storages = FileStorages(fileio: fileio)
        storages.use(.awsS3(region: region, bucket: bucket, endpoint: endpoint), as: .awsS3)
        storages.default(to: .awsS3)
    }

    override class func tearDown() {
        super.tearDown()
        
        storages.shutdown()
    }
    
    // MARK: - private
    
    private var fs: FileStorage {
        let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        return Self.storages.fileStorage(.awsS3, logger: .init(label: "[test-logger]"), on: elg.next())!
    }

    // MARK: - tests

    func testValidBucketNames() {
        [
            "bucket",
            "bucket1",
            "1bucket1",
            "1bu.cke.t1",
            "b-cket"
        ]
        .forEach { value in
            XCTAssertTrue(S3.Bucket(name: value).hasValidName())
        }
    }
    
    func testInvalidBucketNames() {
        [
            ".bucket",
            "bucket-",
            "bUcket",
            "b(cket",
            "b_cket",
            "buck=t",
            "bucke+",
            "bucke+t",
            "bu",
        ]
        .forEach { value in
            XCTAssertFalse(S3.Bucket(name: value).hasValidName())
        }
    }
    
    func testUpload() async throws {
        let key = "test-01.txt"
        let data = Data("file storage test 01".utf8)
        let res = try await fs.upload(key: key, data: data)
        XCTAssertEqual(res, fs.resolve(key: key))
    }

    func testCreateDirectory() async throws {
        let key = "dir01/dir02/dir03"
        let _ = try await fs.createDirectory(key: key)
        let keys1 = try await fs.list(key: "dir01")
        XCTAssertEqual(keys1, ["dir02"])
        let keys2 = try await fs.list(key: "dir01/dir02")
        XCTAssertEqual(keys2, ["dir03"])
    }
    
    func testList() async throws {
        let key1 = "dir02/dir03"
        let _ = try await fs.createDirectory(key: key1)
        
        let key2 = "dir02/test-01.txt"
        let data = Data("test".utf8)
        _ = try await fs.upload(key: key2, data: data)
        
        let res = try await fs.list(key: "dir02")
        XCTAssertEqual(res, ["dir03", "test-01.txt"])
    }
    
    func testExists() async throws {
        let key1 = "non-existing-thing"
        let exists1 = await fs.exists(key: key1)
        XCTAssertFalse(exists1)
        
        let key2 = "my/dir"
        _ = try await fs.createDirectory(key: key2)
        let exists2 = await fs.exists(key: key2)
        XCTAssertTrue(exists2)
    }
    
    func testListFile() async throws {
        let key2 = "dir04/test-01.txt"
        let data = Data("test".utf8)
        _ = try await fs.upload(key: key2, data: data)
        let res = try await fs.list(key: key2)
        XCTAssertEqual(res, [])
    }
    
    func testCopy() async throws {
        let key = "test-02.txt"
        let data = Data("file storage test 02".utf8)
        
        let res = try await fs.upload(key: key, data: data)
        XCTAssertEqual(res, fs.resolve(key: key))
        
        let dest = "test-03.txt"
        let res2 = try await fs.copy(key: key, to: dest)
        XCTAssertEqual(res2, fs.resolve(key: dest))
        
        let res3 = await fs.exists(key: key)
        XCTAssertTrue(res3)
        let res4 = await fs.exists(key: dest)
        XCTAssertTrue(res4)
    }
    
    func testMove() async throws {
        let key = "test-04.txt"
        let data = Data("file storage test 04".utf8)
        let res = try await fs.upload(key: key, data: data)
        XCTAssertEqual(res, fs.resolve(key: key))
        
        let dest = "test-05.txt"
        let res2 = try await fs.move(key: key, to: dest)
        XCTAssertEqual(res2, fs.resolve(key: dest))
        
        let res3 = await fs.exists(key: key)
        XCTAssertFalse(res3)
        let res4 = await fs.exists(key: dest)
        XCTAssertTrue(res4)
    }

    func testGetObject() async throws {
        let key = "test-04.txt"
        let data = Data("file storage test 04".utf8)
        let res = try await fs.upload(key: key, data: data)
        XCTAssertEqual(res, fs.resolve(key: key))

        let obj = try await fs.getObject(key: key)
        XCTAssertNotNil(obj)
        XCTAssertEqual(obj, data)
    }
}
