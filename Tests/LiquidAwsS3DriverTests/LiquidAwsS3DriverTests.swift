import XCTest
import Vapor
@testable import LiquidAwsS3Driver

final class LiquidAwsS3DriverTests: XCTestCase {
    
    static var allTests = [
        ("testValidBucketNames", testValidBucketNames),
        ("testInvalidBucketNames", testInvalidBucketNames),
        ("testUpload", testUpload),
    ]
    
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

    private func createTestStorage(using endpoint: String? = nil) throws -> FileStorage {
        let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let pool = NIOThreadPool(numberOfThreads: 1)
        pool.start()

        let projectRoot = "/" + #file.split(separator: "/").dropLast(3).joined(separator: "/")
        let filePath = projectRoot + "/.env.testing"

        let fileio = NonBlockingFileIO(threadPool: pool)
        let file = try DotEnvFile.read(path: filePath, fileio: fileio, on: elg.next()).wait()
        
        let bucketValue = file.lines.first { $0.key == "BUCKET" }.map { $0.value } ?? ""
        let regionValue = file.lines.first { $0.key == "REGION" }.map { $0.value } ?? ""
        let regionType: Region? = Region(rawValue: regionValue)
        
        guard let region = regionType else {
            fatalError("Invalid `.env.testing` configuration.")
        }
        let bucket = S3.Bucket(name: bucketValue)
        guard bucket.hasValidName() else {
            fatalError("Invalid Bucket name in the config file.")
        }
        
        let eventLoop = EmbeddedEventLoop()
        let storages = FileStorages(fileio: .init(threadPool: .init(numberOfThreads: 1)))
        storages.use(.awsS3(region: region, bucket: bucket, endpoint: endpoint), as: .awsS3)
        return storages.fileStorage(.awsS3, logger: .init(label: "[test-logger]"), on: eventLoop)!
    }
    
    func testUpload() throws {
        let fs = try createTestStorage()
        let key = "test-01"
        let data = Data("file storage test 01".utf8)
        let res = try fs.upload(key: key, data: data).wait()
        let config = fs.context.configuration as! LiquidAwsS3StorageConfiguration
        XCTAssertEqual(res, "https://\(config.bucket.name!).s3-\(config.region.rawValue).amazonaws.com/\(key)")
    }

    /*
    func testUploadWithCustomEndpoint() throws {
        let fs = try createTestStorage(using: "https://s3.custom.com/")
        let key = "test-02"
        let data = Data("file storage test 02".utf8)
        let res = try fs.upload(key: key, data: data).wait()
        let config = fs.context.configuration as! LiquidAwsS3StorageConfiguration
        XCTAssertEqual(res, "\(config.endpoint!)\(config.bucket.name!)/\(key)")
    }
    // */

}
