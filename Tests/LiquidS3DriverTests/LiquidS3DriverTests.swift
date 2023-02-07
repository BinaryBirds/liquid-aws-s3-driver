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

extension ByteBuffer {

    var utf8String: String? {
        guard
            let data = getData(at: 0, length: readableBytes),
            let res = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return res
    }
    
}

open class LiquidS3DriverTestCase: XCTestCase {
    
    func getBasePath() -> String {
        "/" + #file
            .split(separator: "/")
            .dropLast()
            .joined(separator: "/")
    }
    
    func getAssetsPath() -> String {
        getBasePath() + "/Assets/"
    }

    // MARK - dirver setup

    private func createTestObjectStorages(
        logger: Logger
    ) -> ObjectStorages {
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
    ) -> S3ObjectStorage {
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
    
    // MARK: - test setup
    
    var workPath: String!
    var storages: ObjectStorages!
    var os: S3ObjectStorage!

    open override func setUp() {
        workPath = getBasePath() + "/tmp/" + UUID().uuidString + "/"
        
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: workPath),
            withIntermediateDirectories: true
        )

        let logger = Logger(label: "test-logger")
        storages = createTestObjectStorages(logger: logger)
        os = createTestStorage(using: storages, logger: logger)
        
        super.setUp()
    }

    open override func tearDown() {
        try? FileManager.default.removeItem(atPath: workPath)

        storages.shutdown()
        
        super.tearDown()
    }
}
