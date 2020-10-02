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
        return "https://\(bucket).s3-\(region).amazonaws.com"
    }

    /// resolves a file location using a key and the public endpoint URL string
    func resolve(key: String) -> String {
        self.publicEndpoint + "/" + key
    }
    
    /// Uploads a file using a key and a data object
    /// https://docs.aws.amazon.com/general/latest/gr/s3.html
    func upload(key: String, data: Data) -> EventLoopFuture<String> {
        let request = S3.PutObjectRequest(acl: .publicRead,
                                          body: .data(data),
                                          bucket: self.bucket,
                                          contentLength: Int64(data.count),
                                          key: key)

        return self.s3.putObject(request).map { _ in self.resolve(key: key) }
    }

    /// Removes a file resource using a key
    func delete(key: String) -> EventLoopFuture<Void> {
        let request = S3.DeleteObjectRequest(bucket: self.bucket, key: key)
        return self.s3.deleteObject(request).map { _ in }
    }
}


