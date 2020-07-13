//
//  LiquidAwsS3StorageDriver.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import AWSS3

struct LiquidAwsS3StorageDriver: FileStorageDriver {

    let configuration: LiquidAwsS3StorageConfiguration
    private static var client: AWSClient!
    
    init(configuration: LiquidAwsS3StorageConfiguration) {
        self.configuration = configuration
        Self.client = AWSClient(credentialProvider: .static(accessKeyId: configuration.key, secretAccessKey: configuration.secret),
                               httpClientProvider: .createNew)
    }
    
 
    func makeStorage(with context: FileStorageContext) -> FileStorage {
        LiquidAwsS3Storage(configuration: self.configuration, context: context, client: Self.client)
    }
    
    func shutdown() {
        try? Self.client.syncShutdown()
    }
}
