//
//  S3ObjectStorageDriver.swift
//  LiquidS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import LiquidKit
import SotoS3
import SotoCore

struct S3ObjectStorageDriver: ObjectStorageDriver {

    let configuration: S3ObjectStorageConfiguration
    let client: AWSClient
    
    init(
        eventLoopGroup: EventLoopGroup,
        configuration: S3ObjectStorageConfiguration
    ) {
        self.configuration = configuration

        self.client = AWSClient(
            credentialProvider: configuration.credentialProvider,
            options: .init(
                requestLogLevel: .notice,
                errorLogLevel: .notice
            ),
            httpClientProvider: .createNewWithEventLoopGroup(eventLoopGroup)
        )
    }

    func make(
        using context: ObjectStorageContext
    ) -> ObjectStorage {
        let awsUrl = "https://s3.\(configuration.region.rawValue).amazonaws.com"
        let endpoint = configuration.endpoint ?? awsUrl

        let s3 = S3(
            client: client,
            region: configuration.region,
            endpoint: endpoint
        )
        return S3ObjectStorage(
            s3: s3,
            context: context
        )
    }

    func shutdown() {
        try? client.syncShutdown()
    }
}
