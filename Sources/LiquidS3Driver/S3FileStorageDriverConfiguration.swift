//
//  LiquidAwsS3StorageConfiguration.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import LiquidKit
import SotoS3

struct S3FileStorageDriverConfiguration: FileStorageDriverConfiguration {

	enum Provider {
		case s3
		case scaleway
//        case minio
	}

    /// AWSClient credential provider object
    let credentialProvider: CredentialProviderFactory
    
    /// AWS Region
    let region: Region
    
    /// S3 Bucket representation
    let bucket: S3.Bucket
    
    /// custom endpoint for S3
    let endpoint: String?
	
	/// S3 provider
	let provider: Provider

    func makeDriverFactory(
        using storage: FileStorageDriverFactoryStorage
    ) -> FileStorageDriverFactory {
        S3FileStorageDriverFactory(
            configuration: self
        )
    }
}

