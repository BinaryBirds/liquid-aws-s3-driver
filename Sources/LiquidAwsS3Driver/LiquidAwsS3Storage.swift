//
//  LiquidAwsS3Storage.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import Foundation

/// AWS S3 File Storage implementation
struct LiquidAwsS3Storage: FileStorage {
    
    let configuration: LiquidAwsS3StorageConfiguration
    let context: FileStorageContext

    init(configuration: LiquidAwsS3StorageConfiguration, context: FileStorageContext, client: AWSClient) {
        self.configuration = configuration
        self.context = context
        
        guard configuration.bucket.hasValidName() else {
            fatalError("Invalid bucket name")
        }

        self.s3 = S3(client: client, region: configuration.region, endpoint: endpoint)
    }
    
    // MARK: - private

    /// private s3 reference
    private var s3: S3!
    /// private helper for accessing region name
    private var region: String { configuration.region.rawValue }
    /// private helper for accessing bucket name
    private var bucket: String { configuration.bucket.name! }
    /// private helper for accessing the endpoint URL as a String
    private var endpoint: String { configuration.endpoint ?? "https://s3.\(region).amazonaws.com" }
    /// private helper for accessing the publicEndpoint URL as a String
    private var publicEndpoint: String {
        if let customEndpoint = configuration.endpoint {
            return customEndpoint + "/" + bucket
        }
        /// http://www.wryway.com/blog/aws-s3-url-styles/
        if region == "us-east-1" {
            return "https://\(bucket).s3.amazonaws.com"
        }
        return "https://\(bucket).s3-\(region).amazonaws.com"
    }
    
    // MARK: - api

    /// resolves a file location using a key and the public endpoint URL string
    func resolve(key: String) -> String { publicEndpoint + "/" + key }
    
    /// Uploads a file using a key and a data object returning the resolved URL of the uploaded file
    /// https://docs.aws.amazon.com/general/latest/gr/s3.html
    func upload(key: String, data: Data) -> EventLoopFuture<String> {
        s3.putObject(S3.PutObjectRequest(acl: .publicRead, body: .data(data), bucket: bucket, contentLength: Int64(data.count), key: key)).map { _ in resolve(key: key) }
    }

    /// Create a directory structure for a given key
    func createDirectory(key: String) -> EventLoopFuture<Void> {
        s3.putObject(S3.PutObjectRequest(acl: .publicRead, bucket: bucket, contentLength: 0, key: key)).map { _ in }
    }

    /// List objects under a given key
    func list(key: String? = nil) -> EventLoopFuture<[String]> {
        s3.listObjects(S3.ListObjectsRequest(bucket: bucket, prefix: key)).map { list -> [String] in
            if let prefix = key {
                return list.contents?.compactMap { $0.key?.split(separator: "/").dropFirst(prefix.split(separator: "/").count).map(String.init).first } ?? []
            }
            return Array(Set(list.contents?.compactMap { $0.key?.split(separator: "/").map(String.init).first } ?? []))
        }
    }
    
    func copy(key source: String, to destination: String) -> EventLoopFuture<String> {
        exists(key: source).flatMap { exists in
            guard exists else {
                return s3.eventLoopGroup.next().makeFailedFuture(LiquidError.keyNotExists)
            }
            return s3.copyObject(S3.CopyObjectRequest(acl: .publicRead, bucket: bucket, copySource: bucket + "/" + source, key: destination)).map { _ in resolve(key: destination) }
        }
    }
    
    func move(key source: String, to destination: String) -> EventLoopFuture<String> {
        exists(key: source).flatMap { exists in
            guard exists else {
                return s3.eventLoopGroup.next().makeFailedFuture(LiquidError.keyNotExists)
            }
            return copy(key: source, to: destination).flatMap { key in delete(key: source).map { key } }
        }
    }

    /// Removes a file resource using a key
    func delete(key: String) -> EventLoopFuture<Void> {
        s3.deleteObject(S3.DeleteObjectRequest(bucket: bucket, key: key)).map { _ in }
    }

    func exists(key: String) -> EventLoopFuture<Bool> {
        s3.getObject(S3.GetObjectRequest(bucket: bucket, key: key)).map { _ in true }.flatMapError { err -> EventLoopFuture<Bool> in
            if let err = err as? SotoS3.S3ErrorType, err == SotoS3.S3ErrorType.noSuchKey {
                return s3.eventLoopGroup.next().makeSucceededFuture(false)
            }
            return s3.eventLoopGroup.next().makeFailedFuture(err)
        }
    }
}


