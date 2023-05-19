//
//  S3ObjectStorageConfiguration.swift
//  LiquidS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import LiquidKit
import SotoS3

struct S3ObjectStorageConfiguration: ObjectStorageConfiguration {

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
    
    /// Custom log level for the AWS client
    let logLevel: Logger.Level
    
    /// custom logger
    let logger: Logger

    ///
    /// Creates the driver factory
    ///
    func make(
        using storages: ObjectStorages
    ) -> ObjectStorageDriver {
        S3ObjectStorageDriver(
            eventLoopGroup: storages.eventLoopGroup,
            configuration: self,
            logLevel: logLevel,
            logger: logger
        )
    }
}

