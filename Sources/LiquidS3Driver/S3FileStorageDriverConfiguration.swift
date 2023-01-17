//
//  LiquidAwsS3StorageConfiguration.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import LiquidKit
import SotoS3

struct S3FileStorageDriverConfiguration: FileStorageDriverConfiguration {

    /// AWSClient credential provider object
    let credentialProvider: CredentialProviderFactory
    
    /// AWS Region
    let region: Region
    
    /// S3 Bucket representation
    let bucket: S3.Bucket
    
    /// custom endpoint
    let endpoint: String?

    /// custom public endpoint
    let publicEndpoint: String?

    func makeDriverFactory(
        using storage: FileStorageDriverFactoryStorage
    ) -> FileStorageDriverFactory {
        S3FileStorageDriverFactory(
            eventLoopGroup: storage.eventLoopGroup,
            configuration: self
        )
    }
}

