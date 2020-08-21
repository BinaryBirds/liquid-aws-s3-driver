//
//  FileStorageConfigurationFactory.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

public extension FileStorageConfigurationFactory {

    /// creates a new Liquid FileStorageConfigurationFactory object using the provided S3 configuration 
    static func awsS3(credentialProvider: CredentialProviderFactory = .default,
                      region: Region,
                      bucket: S3.Bucket,
                      endpoint: String? = nil) -> FileStorageConfigurationFactory {
        .init {
            LiquidAwsS3StorageConfiguration(credentialProvider: credentialProvider,
                                            region: region,
                                            bucket: bucket,
                                            endpoint: endpoint)
        }
    }
}
