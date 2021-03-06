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
    
    func testUpload() throws {
        let key = "test-01.txt"
        let data = Data("file storage test 01".utf8)
        let res = try fs.upload(key: key, data: data).wait()
        XCTAssertEqual(res, fs.resolve(key: key))
    }

    func testCreateDirectory() throws {
        let key = "dir01/dir02/dir03"
        let _ = try fs.createDirectory(key: key).wait()
        let keys1 = try fs.list(key: "dir01").wait()
        XCTAssertEqual(keys1, ["dir02"])
        let keys2 = try fs.list(key: "dir01/dir02").wait()
        XCTAssertEqual(keys2, ["dir03"])
    }
    
    func testList() throws {
        let key1 = "dir02/dir03"
        let _ = try fs.createDirectory(key: key1).wait()
        
        let key2 = "dir02/test-01.txt"
        let data = Data("test".utf8)
        _ = try fs.upload(key: key2, data: data).wait()
        
        let res = try fs.list(key: "dir02").wait()
        XCTAssertEqual(res, ["dir03", "test-01.txt"])
    }
    
    func testExists() throws {
        let key1 = "non-existing-thing"
        let exists1 = try fs.exists(key: key1).wait()
        XCTAssertFalse(exists1)
        
        let key2 = "my/dir"
        _ = try fs.createDirectory(key: key2).wait()
        let exists2 = try fs.exists(key: key2).wait()
        XCTAssertTrue(exists2)
    }
    
    func testListFile() throws {
        let key2 = "dir04/test-01.txt"
        let data = Data("test".utf8)
        _ = try fs.upload(key: key2, data: data).wait()
        let res = try fs.list(key: key2).wait()
        XCTAssertEqual(res, [])
    }
    
    func testCopy() throws {
        let key = "test-02.txt"
        let data = Data("file storage test 02".utf8)
        
        let res = try fs.upload(key: key, data: data).wait()
        XCTAssertEqual(res, fs.resolve(key: key))
        
        let dest = "test-03.txt"
        let res2 = try fs.copy(key: key, to: dest).wait()
        XCTAssertEqual(res2, fs.resolve(key: dest))
        
        let res3 = try fs.exists(key: key).wait()
        XCTAssertTrue(res3)
        let res4 = try fs.exists(key: dest).wait()
        XCTAssertTrue(res4)
    }
    
    func testMove() throws {
        let key = "test-04.txt"
        let data = Data("file storage test 04".utf8)
        let res = try fs.upload(key: key, data: data).wait()
        XCTAssertEqual(res, fs.resolve(key: key))
        
        let dest = "test-05.txt"
        let res2 = try fs.move(key: key, to: dest).wait()
        XCTAssertEqual(res2, fs.resolve(key: dest))
        
        let res3 = try fs.exists(key: key).wait()
        XCTAssertFalse(res3)
        let res4 = try fs.exists(key: dest).wait()
        XCTAssertTrue(res4)
    }

}
