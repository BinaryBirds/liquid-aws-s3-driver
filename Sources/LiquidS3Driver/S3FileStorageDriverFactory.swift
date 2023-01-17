//
//  S3FileStorageDriverFactory.swift
//  LiquidS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import LiquidKit
import SotoS3
import SotoCore

struct S3FileStorageDriverFactory: FileStorageDriverFactory {

    let configuration: S3FileStorageDriverConfiguration
    let client: AWSClient
    
    init(
        eventLoopGroup: EventLoopGroup,
        configuration: S3FileStorageDriverConfiguration
    ) {
        self.configuration = configuration
        self.client = AWSClient(
            credentialProvider: configuration.credentialProvider,
            httpClientProvider: .createNewWithEventLoopGroup(eventLoopGroup)
        )
    }

    func makeDriver(
        using context: FileStorageDriverContext
    ) -> FileStorageDriver {
        let awsUrl = "https://s3.\(configuration.region.rawValue).amazonaws.com"
        let endpoint = configuration.endpoint ?? awsUrl

        let s3 = S3(
            client: client,
            region: configuration.region,
            endpoint: endpoint
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
