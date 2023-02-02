//
//  LiquidS3DriverTests.swift
//  LiquidS3DriverTests
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//


import XCTest
import LiquidKit
import Logging
import NIO
@testable import LiquidS3Driver

final class LiquidS3DriverTests: XCTestCase {

    private func getBasePath() -> String {
        "/" + #file
            .split(separator: "/")
            .dropLast()
            .joined(separator: "/")
    }

    private func createTestObjectStorages(
        logger: Logger
    ) throws -> ObjectStorages {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let pool = NIOThreadPool(numberOfThreads: 1)
        let fileio = NonBlockingFileIO(threadPool: pool)
        pool.start()

        return .init(
            eventLoopGroup: eventLoopGroup,
            byteBufferAllocator: .init(),
            fileio: fileio
        )
    }

    private func createTestStorage(
        using storages: ObjectStorages,
        logger: Logger
    ) throws -> S3ObjectStorage {
        let env = ProcessInfo.processInfo.environment

        storages.use(
            .s3(
                credentialProvider: .static(
                    accessKeyId: env["ACCESS_KEY"] ?? "",
                    secretAccessKey: env["ACCESS_SECRET"] ?? ""
                ),
                region: .init(rawValue: env["REGION"] ?? ""),
                bucket: .init(name: env["BUCKET"] ?? ""),
                endpoint: env["ENDPOINT"],
                publicEndpoint: env["PUBLIC_ENDPOINT"]
            ),
            as: .s3
        )

        return storages.make(
            logger: logger,
            on: storages.eventLoopGroup.next()
        )! as! S3ObjectStorage
    }

    // MARK: - tests

    func testUpload() async throws {
        let logger = Logger(label: "test-logger")
        let storages = try createTestObjectStorages(logger: logger)
        let os = try createTestStorage(using: storages, logger: logger)
        defer { storages.shutdown() }

        let key = "test-01.txt"
        let data = Data("file storage test 01".utf8)
        try await os.upload(
            key: key,
            buffer: .init(data: data),
            checksum: nil
        )
    }
    
    func testUploadValidChecksum() async throws {
        let logger = Logger(label: "test-logger")
        let storages = try createTestObjectStorages(logger: logger)
        let os = try createTestStorage(using: storages, logger: logger)
        defer { storages.shutdown() }
        
        let key = "test-01.txt"
        let data = Data("file storage test 01".utf8)
        
        let calculator = os.createChecksumCalculator()
        calculator.update(.init(data))
        let checksum = calculator.finalize()

        try await os.upload(
            key: key,
            buffer: .init(data: data),
            checksum: checksum
        )
    }
    
    func testUploadInvalidChecksum() async throws {
        let logger = Logger(label: "test-logger")
        let storages = try createTestObjectStorages(logger: logger)
        let os = try createTestStorage(using: storages, logger: logger)
        defer { storages.shutdown() }
        
        let key = "test-01.txt"
        let data = Data("file storage test 01".utf8)

        do {
            try await os.upload(
                key: key,
                buffer: .init(data: data),
                checksum: "invalid"
            )
            XCTFail("Should fail with invalid checksum error.")
        }
        catch ObjectStorageError.invalidChecksum {
            // we're good
        }
    }

    func testcreate() async throws {
        let logger = Logger(label: "test-logger")
        let storages = try createTestObjectStorages(logger: logger)
        let os = try createTestStorage(using: storages, logger: logger)
        defer { storages.shutdown() }

        let key = "dir01/dir02/dir03"
        try await os.create(key: key)
        let keys1 = try await os.list(key: "dir01")
        XCTAssertEqual(keys1, ["dir02"])
        let keys2 = try await os.list(key: "dir01/dir02")
        XCTAssertEqual(keys2, ["dir03"])
    }

    func testList() async throws {
        let logger = Logger(label: "test-logger")
        let storages = try createTestObjectStorages(logger: logger)
        let os = try createTestStorage(using: storages, logger: logger)
        defer { storages.shutdown() }

        let key1 = "dir02/dir03"
        try await os.create(key: key1)

        let key2 = "dir02/test-01.txt"
        let data = Data("test".utf8)
        try await os.upload(
            key: key2,
            buffer: .init(data: data),
            checksum: nil
        )

        let res = try await os.list(key: "dir02")
        XCTAssertEqual(res, ["dir03", "test-01.txt"])
    }

    func testExists() async throws {
        let logger = Logger(label: "test-logger")
        let storages = try createTestObjectStorages(logger: logger)
        let os = try createTestStorage(using: storages, logger: logger)
        defer { storages.shutdown() }

        let key1 = "non-existing-thing"
        let exists1 = await os.exists(key: key1)
        XCTAssertFalse(exists1)
        
        let key2 = "my/dir"
        try await os.create(key: key2)
        let exists2 = await os.exists(key: key2)
        XCTAssertTrue(exists2)
    }
    
    func testListFile() async throws {
        let logger = Logger(label: "test-logger")
        let storages = try createTestObjectStorages(logger: logger)
        let os = try createTestStorage(using: storages, logger: logger)
        defer { storages.shutdown() }
        
        let key2 = "dir04/test-01.txt"
        let data = Data("test".utf8)
        try await os.upload(
            key: key2,
            buffer: .init(data: data),
            checksum: nil
        )
        let res = try await os.list(key: key2)
        XCTAssertEqual(res, [])
    }
    
    func testCopy() async throws {
        let logger = Logger(label: "test-logger")
        let storages = try createTestObjectStorages(logger: logger)
        let os = try createTestStorage(using: storages, logger: logger)
        defer { storages.shutdown() }
        
        let key = "test-02.txt"
        let data = Data("file storage test 02".utf8)
        
        try await os.upload(
            key: key,
            buffer: .init(data: data),
            checksum: nil
        )

        let dest = "test-03.txt"
        try await os.copy(key: key, to: dest)
        
        let res3 = await os.exists(key: key)
        XCTAssertTrue(res3)
        
        let res4 = await os.exists(key: dest)
        XCTAssertTrue(res4)
    }
    
    func testMove() async throws {
        let logger = Logger(label: "test-logger")
        let storages = try createTestObjectStorages(logger: logger)
        let os = try createTestStorage(using: storages, logger: logger)
        defer { storages.shutdown() }
        
        let key = "test-04.txt"
        let data = Data("file storage test 04".utf8)
        try await os.upload(
            key: key,
            buffer: .init(data: data),
            checksum: nil
        )

        let dest = "test-05.txt"
        try await os.move(key: key, to: dest)

        let res3 = await os.exists(key: key)
        XCTAssertFalse(res3)

        let res4 = await os.exists(key: dest)
        XCTAssertTrue(res4)
    }

    func testDownload() async throws {
        let logger = Logger(label: "test-logger")
        let storages = try createTestObjectStorages(logger: logger)
        let os = try createTestStorage(using: storages, logger: logger)
        defer { storages.shutdown() }
        
        let key = "test-04.txt"
        let data = Data("file storage test 04".utf8)
        try await os.upload(
            key: key,
            buffer: .init(data: data),
            checksum: nil
        )
        
        let buffer = try await os.download(key: key)
        let res = buffer.getData(at: 0, length: buffer.readableBytes)
        XCTAssertEqual(res, data)
    }
    
    func testMultipartUpload() async throws {
        
        let basePath = getBasePath()
        let key = "test-image.jpg"
        
        // credits -> https://unsplash.com/photos/rTZW4f02zY8
        let filePath = "/Assets/" + key

        let handle = FileHandle(forReadingAtPath: basePath + filePath)!
        let count = 6_000_000
        let data1 = try handle.read(upToCount: count)!
        try handle.seek(toOffset: UInt64(count))
        let data2 = try handle.readToEnd()!
        
        let logger = Logger(label: "test-logger")
        let storages = try createTestObjectStorages(logger: logger)
        let os = try createTestStorage(using: storages, logger: logger)
        defer { storages.shutdown() }
        
        let uploadId = try await os.createMultipartUpload(key: key)
        
        let chunk1 = try await os.uploadMultipartChunk(
            key: key,
            buffer: .init(data: data1),
            uploadId: uploadId,
            partNumber: 1
        )
        
        let chunk2 = try await os.uploadMultipartChunk(
            key: key,
            buffer: .init(data: data2),
            uploadId: uploadId,
            partNumber: 2
        )

        let data = try Data(contentsOf: URL(fileURLWithPath: basePath + filePath))
        let calculator = os.createChecksumCalculator()
        calculator.update(.init(data))
        let checksum = calculator.finalize()

        try await os.completeMultipartUpload(
            key: key,
            uploadId: uploadId,
            checksum: checksum,
            chunks: [
                chunk1,
                chunk2,
            ]
        )
    }
}
