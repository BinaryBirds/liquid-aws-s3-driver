//
//  ObjectStorageConfigurationFactory+S3.swift
//  LiquidS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import LiquidKit
import SotoS3

public extension ObjectStorageConfigurationFactory {

    ///
    /// Creates a new factory object using the provided S3 configuration
    ///
    static func s3(
        credentialProvider: CredentialProviderFactory = .default,
        region: Region,
        bucket: S3.Bucket,
        endpoint: String? = nil,
        publicEndpoint: String? = nil,
        logLevel: Logger.Level = .notice,
        logger: Logger = AWSClient.loggingDisabled
    ) -> ObjectStorageConfigurationFactory {
        .init {
            S3ObjectStorageConfiguration(
                credentialProvider: credentialProvider,
                region: region,
                bucket: bucket,
                endpoint: endpoint,
                publicEndpoint: publicEndpoint,
                logLevel: logLevel,
                logger: logger
            )
        }
    }
}
