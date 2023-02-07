//
//  Header.h
//  
//
//  Created by Tibor Bodecs on 2023. 02. 07..
//

import XCTest
import LiquidKit
import Logging
import NIO
@testable import LiquidS3Driver

final class LiquidS3DriverTests_Streams: LiquidS3DriverTestCase {
    
    func testDownloadStream() async throws {
        let key = "test-image.jpg"
        let assetPath = getAssetsPath() + key
        let filePath = workPath + "dl.jpg"

        FileManager.default.createFile(atPath: filePath, contents: nil)
        let handle = FileHandle(forWritingAtPath: filePath)!
        for try await buffer in os.download(key: key) {
            handle.write(.init(buffer: buffer))
        }
        try handle.close()
        
        let assetData = try Data(contentsOf: URL(fileURLWithPath: assetPath))
        let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        XCTAssertEqual(assetData, fileData)
    }
    
    func testMultipartUpload() async throws {
        let key = "test-image.jpg"
        let filePath = getAssetsPath() + key

        let count = 5 * 1024 * 1024
        let handle = FileHandle(forReadingAtPath: filePath)!
        
        let uploadId = try await os.createMultipartUpload(key: key)

        let data1 = try handle.read(upToCount: count)!
        let chunk1 = try await os.uploadMultipartChunk(
            key: key,
            buffer: .init(data: data1),
            uploadId: uploadId,
            partNumber: 1
        )
        
        try handle.seek(toOffset: UInt64(count))
        let data2 = try handle.readToEnd()!
        let chunk2 = try await os.uploadMultipartChunk(
            key: key,
            buffer: .init(data: data2),
            uploadId: uploadId,
            partNumber: 2
        )

        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
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
    
    func testLargeMultipartUpload() async throws {
        let key = "test.avi"
        let filePath = getAssetsPath() + key
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            return print("NOTICE: skipping large file multipart upload test...")
        }

        let handle = FileHandle(forReadingAtPath: filePath)!
        let bufSize = 30 * 1024 * 1024 // x MB chunks
        
        let attr = try FileManager.default.attributesOfItem(atPath: filePath)
        let fileSize = attr[FileAttributeKey.size] as! UInt64
        var num = fileSize / UInt64(bufSize)
        let rem = fileSize % UInt64(bufSize)
        if rem > 0 {
            num += 1
        }
        
        let uploadId = try await os.createMultipartUpload(key: key)
        let calculator = os.createChecksumCalculator()
        var chunks: [MultipartUpload.Chunk] = []
        for i in 0..<num {
            let data: Data
            try handle.seek(toOffset: UInt64(bufSize) * i)
            print(i, UInt64(bufSize) * i)

            if i == num - 1 {
                data = try handle.readToEnd()!
            }
            else {
                data = try handle.read(upToCount: bufSize)!
            }

            calculator.update(.init(data))

            let chunk = try await os.uploadMultipartChunk(
                key: key,
                buffer: .init(data: data),
                uploadId: uploadId,
                partNumber: Int(i + 1)
            )
            chunks.append(chunk)
        }
        
        let checksum = calculator.finalize()
        
        try await os.completeMultipartUpload(
            key: key,
            uploadId: uploadId,
            checksum: checksum,
            chunks: chunks
        )
    }
    
}
