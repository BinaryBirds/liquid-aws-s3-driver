//
//  LiquidAwsS3StorageDriver.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import LiquidKit
import SotoS3

struct S3FileStorageDriverFactory: FileStorageDriverFactory {

    let configuration: S3FileStorageDriverConfiguration

    private let client: AWSClient
    
    init(
        configuration: S3FileStorageDriverConfiguration
    ) {
        self.configuration = configuration
        self.client = AWSClient(
            credentialProvider: configuration.credentialProvider,
            httpClientProvider: .createNew
        )
    }

    func makeDriver(
        using context: FileStorageDriverContext
    ) -> FileStorageDriver {
        let s3 = S3(
            client: client,
            region: configuration.region,
            endpoint: configuration.endpoint
        )
        return S3FileStorageDriver(
            s3: s3,
            context: context
        )
    }

    func shutdown() {
        try? client.syncShutdown()
    }
}
