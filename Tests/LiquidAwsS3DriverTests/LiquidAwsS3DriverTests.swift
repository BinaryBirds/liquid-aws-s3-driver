import XCTest
@testable import LiquidAwsS3Driver

final class LiquidAwsS3DriverTests: XCTestCase {
    
    let key = "****"
    let secret = "****"
    let bucket = "bucket"
    let region = Region.uswest1
    let customEndpoint = "https://s3.custom.com/"

    private func createTestStorage(withEndpoint endpoint: String? = nil) -> FileStorage {
        let eventLoop = EmbeddedEventLoop()
        let storages = FileStorages(fileio: .init(threadPool: .init(numberOfThreads: 1)))
        storages.use(try! .awsS3(key: self.key, secret: self.secret, bucket: self.bucket, region: self.region), as: .awsS3)
        return storages.fileStorage(.awsS3, logger: .init(label: ""), on: eventLoop)!
    }

    static var allTests = [
        ("testUpload", testUpload),
    ]

    func testUpload() throws {
        let fs = self.createTestStorage()
        let key = "test"
        let data = Data("file storage test".utf8)
        let res = try fs.upload(key: key, data: data).wait()
        XCTAssertEqual(res, "https://\(self.bucket).s3-\(self.region.rawValue).amazonaws.com/\(key)")
    }

    func testCustomEndpointUpload() throws {
        let fs = self.createTestStorage(withEndpoint: customEndpoint)
        let key = "test"
        let data = Data("file storage test".utf8)
        let res = try fs.upload(key: key, data: data).wait()
        XCTAssertEqual(res, "\(self.customEndpoint)\(self.bucket)/\(key)")
    }

    func testBucketNames() {
        let validBucketNames = [
            "bucket",
            "bucket1",
            "1bucket1",
            "1bu.cke.t1",
            "b-cket"
        ]

        let invalidBucketNames = [
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

        for goodBucketName in validBucketNames {
            XCTAssertNoThrow(try LiquidAwsS3StorageConfiguration(key: key, secret: secret, bucket: goodBucketName, region: region, endpoint: nil))
        }

        for badBucketName in invalidBucketNames {
            XCTAssertThrowsError(try LiquidAwsS3StorageConfiguration(key: key, secret: secret, bucket: badBucketName, region: region, endpoint: nil))
        }
    }
}
