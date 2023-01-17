//
//  S3FileStorageDriver.swift
//  LiquidS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import Foundation
import LiquidKit
import SotoS3

///
/// S3 File Storage implementation
/// 
struct S3FileStorageDriver {
	
    let s3: S3
    let context: FileStorageDriverContext

	init(
        s3: S3,
        context: FileStorageDriverContext
    ) {
        self.s3 = s3
        self.context = context
    }
}

private extension S3FileStorageDriver {

    var configuration: S3FileStorageDriverConfiguration {
        context.configuration as! S3FileStorageDriverConfiguration
    }

    var region: String { configuration.region.rawValue }

    var bucketName: String { configuration.bucket.name! }

    var publicEndpoint: String {
        if let endpoint = configuration.publicEndpoint {
            return endpoint
        }
        if configuration.region == .useast1 {
            return "https://\(bucketName).s3.amazonaws.com"
        }
        return "https://\(bucketName).s3-\(region).amazonaws.com"
    }
}

extension S3FileStorageDriver: FileStorageDriver {
    
    ///
    /// Resolves a file location using a key and the public endpoint URL string
    ///
    func resolve(
        key: String
    ) -> String {
        publicEndpoint + "/" + key
    }
    
    ///
    /// Uploads a file using a key and a data object returning the resolved URL of the uploaded file
    ///
    /// https://docs.aws.amazon.com/general/latest/gr/s3.html
    ///
    func upload(
        key: String,
        data: Data
    ) async throws -> String {
        _ = try await s3.putObject(
            S3.PutObjectRequest(
                acl: .publicRead,
                body: .data(data),
                bucket: bucketName,
                contentLength: Int64(data.count),
                key: key
            ),
            logger: context.logger,
            on: context.eventLoop
        )
        return resolve(key: key)
    }

    ///
    /// Create a directory structure for a given key
    ///
    func createDirectory(
        key: String
    ) async throws {
        _ = try await s3.putObject(
            S3.PutObjectRequest(
                acl: .publicRead,
                bucket: bucketName,
                contentLength: 0,
                key: key
            ),
            logger: context.logger,
            on: context.eventLoop
        )
    }

    ///
    /// List objects under a given key (returning the relative keys)
    ///
    func list(
        key: String? = nil
    ) async throws -> [String] {
        let list = try await s3.listObjects(
            S3.ListObjectsRequest(
                bucket: bucketName,
                prefix: key
            ),
            logger: context.logger,
            on: context.eventLoop
        )
        let keys = (list.contents ?? []).map(\.key).compactMap { $0 }
        var dropCount = 0
        if let prefix = key {
            dropCount = prefix.split(separator: "/").count
        }
        return keys.compactMap {
            $0.split(separator: "/").dropFirst(dropCount).map(String.init).first
        }
    }
    
    ///
    /// Copy existing object to a new key
    ///
    func copy(
        key source: String,
        to destination: String
    ) async throws -> String {
        let exists = await exists(key: source)
        guard exists else {
            throw FileStorageDriverError.keyNotExists
        }
        _ = try await s3.copyObject(
            S3.CopyObjectRequest(
                acl: .publicRead,
                bucket: bucketName,
                copySource: bucketName + "/" + source,
                key: destination
            ),
            logger: context.logger,
            on: context.eventLoop
        )
        return resolve(key: destination)
    }
    
    ///
    /// Move existing object to a new key
    ///
    func move(
        key source: String,
        to destination: String
    ) async throws -> String {
        let exists = await exists(key: source)
        guard exists else {
            throw FileStorageDriverError.keyNotExists
        }
        let key = try await copy(key: source, to: destination)
        try await delete(key: source)
        return key
        
    }

    ///
    /// Get object data using a key
    ///
    func getObject(
        key source: String
    ) async throws -> Data? {
        let exists = await exists(key: source)
        guard exists else {
            throw FileStorageDriverError.keyNotExists
        }
        let response = try await s3.getObject(
            S3.GetObjectRequest(
                bucket: bucketName,
                key: source
            ),
            logger: context.logger,
            on: context.eventLoop
        )
        return response.body?.asData()
    }

    ///
    /// Removes a file resource using a key
    ///
    func delete(
        key: String
    ) async throws -> Void {
        _ = try await s3.deleteObject(
            S3.DeleteObjectRequest(
                bucket: bucketName,
                key: key
            ),
            logger: context.logger,
            on: context.eventLoop
        )
    }

    ///
    /// Check if a file exists using a key
    ///
    func exists(
        key: String
    ) async -> Bool {
        do {
            _ = try await s3.getObject(
                S3.GetObjectRequest(
                    bucket: bucketName,
                    key: key
                ),
                logger: context.logger,
                on: context.eventLoop
            )
            return true
        }
        catch {
            return false
        }
    }
}
