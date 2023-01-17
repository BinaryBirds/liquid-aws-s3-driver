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
    
    func createTestDriverStorage(
        logger: Logger
    ) throws -> FileStorageDriverFactoryStorage {
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

    func createTestDriver(
        using storage: FileStorageDriverFactoryStorage,
        logger: Logger
    ) throws -> S3FileStorageDriver {
        let env = ProcessInfo.processInfo.environment

        storage.use(
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

        return storage.makeDriver(
            logger: logger,
            on: storage.eventLoopGroup.next()
        )! as! S3FileStorageDriver
    }

    // MARK: - tests

    func testUpload() async throws {
        let logger = Logger(label: "test-logger")
        let storage = try createTestDriverStorage(logger: logger)
        let fs = try createTestDriver(using: storage, logger: logger)
        defer { storage.shutdown() }
        let key = "test-01.txt"
        let data = Data("file storage test 01".utf8)
        let res = try await fs.upload(key: key, data: data)
        XCTAssertEqual(res, fs.resolve(key: key))
    }

    func testCreateDirectory() async throws {
        let logger = Logger(label: "test-logger")
        let storage = try createTestDriverStorage(logger: logger)
        let fs = try createTestDriver(using: storage, logger: logger)
        defer { storage.shutdown() }
        
        let key = "dir01/dir02/dir03"
        let _ = try await fs.createDirectory(key: key)
        let keys1 = try await fs.list(key: "dir01")
        XCTAssertEqual(keys1, ["dir02"])
        let keys2 = try await fs.list(key: "dir01/dir02")
        XCTAssertEqual(keys2, ["dir03"])
    }

    func testList() async throws {
        let logger = Logger(label: "test-logger")
        let storage = try createTestDriverStorage(logger: logger)
        let fs = try createTestDriver(using: storage, logger: logger)
        defer { storage.shutdown() }

        let key1 = "dir02/dir03"
        let _ = try await fs.createDirectory(key: key1)
        
        let key2 = "dir02/test-01.txt"
        let data = Data("test".utf8)
        _ = try await fs.upload(key: key2, data: data)
        
        let res = try await fs.list(key: "dir02")
        XCTAssertEqual(res, ["dir03", "test-01.txt"])
    }

    func testExists() async throws {
        let logger = Logger(label: "test-logger")
        let storage = try createTestDriverStorage(logger: logger)
        let fs = try createTestDriver(using: storage, logger: logger)
        defer { storage.shutdown() }

        let key1 = "non-existing-thing"
        let exists1 = await fs.exists(key: key1)
        XCTAssertFalse(exists1)
        
        let key2 = "my/dir"
        _ = try await fs.createDirectory(key: key2)
        let exists2 = await fs.exists(key: key2)
        XCTAssertTrue(exists2)
    }
    
    func testListFile() async throws {
        let logger = Logger(label: "test-logger")
        let storage = try createTestDriverStorage(logger: logger)
        let fs = try createTestDriver(using: storage, logger: logger)
        defer { storage.shutdown() }
        
        let key2 = "dir04/test-01.txt"
        let data = Data("test".utf8)
        _ = try await fs.upload(key: key2, data: data)
        let res = try await fs.list(key: key2)
        XCTAssertEqual(res, [])
    }
    
    func testCopy() async throws {
        let logger = Logger(label: "test-logger")
        let storage = try createTestDriverStorage(logger: logger)
        let fs = try createTestDriver(using: storage, logger: logger)
        defer { storage.shutdown() }
        
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
        let logger = Logger(label: "test-logger")
        let storage = try createTestDriverStorage(logger: logger)
        let fs = try createTestDriver(using: storage, logger: logger)
        defer { storage.shutdown() }
        
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
        let logger = Logger(label: "test-logger")
        let storage = try createTestDriverStorage(logger: logger)
        let fs = try createTestDriver(using: storage, logger: logger)
        defer { storage.shutdown() }
        
        let key = "test-04.txt"
        let data = Data("file storage test 04".utf8)
        let res = try await fs.upload(key: key, data: data)
        XCTAssertEqual(res, fs.resolve(key: key))

        let obj = try await fs.getObject(key: key)
        XCTAssertNotNil(obj)
        XCTAssertEqual(obj, data)
    }
}
