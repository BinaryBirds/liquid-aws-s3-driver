//
//  FileStorageConfigurationFactory.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import LiquidKit
import SotoS3

public extension FileStorageDriverConfigurationFactory {

    ///
    /// Creates a new factory object using the provided S3 configuration
    ///
    static func s3(
        credentialProvider: CredentialProviderFactory = .default,
        region: Region,
        bucket: S3.Bucket,
        endpoint: String? = nil,
        publicEndpoint: String? = nil
    ) -> FileStorageDriverConfigurationFactory {
        .init {
            S3FileStorageDriverConfiguration(
                credentialProvider: credentialProvider,
                region: region,
                bucket: bucket,
                endpoint: endpoint,
                publicEndpoint: publicEndpoint
            )
        }
    }
}
