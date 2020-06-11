//
//  LiquidAwsS3Storage.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import Foundation
import AWSS3

struct LiquidAwsS3Storage: FileStorage {

    let configuration: LiquidAwsS3StorageConfiguration
    let context: FileStorageContext
    
    private var s3: S3
    
    init(configuration: LiquidAwsS3StorageConfiguration, context: FileStorageContext) {
        self.configuration = configuration
        self.context = context
        let endpoint = configuration.endpoint ?? "https://s3.\(configuration.region.rawValue).amazonaws.com"
        self.s3 = S3(accessKeyId: configuration.key,
                     secretAccessKey: configuration.secret,
                     region: configuration.region,
                     endpoint: endpoint,
                     middlewares: [])
    }
    
    private var bucket: String {
        self.configuration.bucket
    }

    private var publicUrl: URL {
        if let endpointStr = self.configuration.endpoint, let endpointURL = URL(string: endpointStr) {
            return endpointURL.appendingPathComponent(self.configuration.bucket)
        } else {
            return URL(string: "https://\(self.configuration.bucket).s3-\(self.configuration.region.rawValue).amazonaws.com")!
        }
    }

    func resolve(key: String) -> String {
        self.publicUrl.appendingPathComponent(key).absoluteString
    }
    
    func upload(key: String, data: Data) -> EventLoopFuture<String> {
        //https://docs.aws.amazon.com/general/latest/gr/s3.html
        let putRequest = S3.PutObjectRequest(acl: .publicRead,
            body: .data(data),
            bucket: self.bucket,
            contentLength: Int64(data.count),
            key: key)

        return self.s3.putObject(putRequest).map { output in
            print(output)
            return self.resolve(key: key)
        }
    }

    func delete(key: String) -> EventLoopFuture<Void> {
        let deleteRequest = S3.DeleteObjectRequest(bucket: self.bucket, key: key)
        return self.s3.deleteObject(deleteRequest).map { output in
            print(output)
        }
    }
}


