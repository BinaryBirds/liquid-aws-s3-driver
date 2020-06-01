import XCTest
@testable import LiquidAwsS3Driver

final class LiquidAwsS3DriverTests: XCTestCase {
    
    let key = "****"
    let secret = "****"
    let bucket = "****"
    let region = Region.uswest1

    private func createTestStorage() -> FileStorage {
        let eventLoop = EmbeddedEventLoop()
        let storages = FileStorages(fileio: .init(threadPool: .init(numberOfThreads: 1)))
        storages.use(.awsS3(key: self.key, secret: self.secret, bucket: self.bucket, region: self.region), as: .awsS3)
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
}
