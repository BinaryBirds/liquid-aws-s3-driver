//
//  LiquidAwsS3StorageConfiguration.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

struct LiquidAwsS3StorageConfiguration: FileStorageConfiguration {

    /// AWSClient credential provider object
    let credentialProvider: CredentialProviderFactory
    
    /// AWS Region
    let region: Region
    
    /// S3 Bucket representation
    let bucket: S3.Bucket
    
    /// custom endpoint for S3
    let endpoint: String?

    /// creates a new FileStrorageDriver using the AWS S3 configuration object
    func makeDriver(for databases: FileStorages) -> FileStorageDriver {
        LiquidAwsS3StorageDriver(configuration: self)
    }
}

