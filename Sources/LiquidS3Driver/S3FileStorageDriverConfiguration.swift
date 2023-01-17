//
//  S3FileStorageDriverConfiguration.swift
//  LiquidS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import LiquidKit
import SotoS3

struct S3FileStorageDriverConfiguration: FileStorageDriverConfiguration {

    /// Credential provider object
    let credentialProvider: CredentialProviderFactory
    
    /// Region
    let region: Region
    
    /// Bucket
    let bucket: S3.Bucket
    
    /// Custom endpoint
    let endpoint: String?

    /// Custom public endpoint
    let publicEndpoint: String?

    ///
    /// Creates the driver factory
    ///
    func makeDriverFactory(
        using storage: FileStorageDriverFactoryStorage
    ) -> FileStorageDriverFactory {
        S3FileStorageDriverFactory(
            eventLoopGroup: storage.eventLoopGroup,
            configuration: self
        )
    }
}

