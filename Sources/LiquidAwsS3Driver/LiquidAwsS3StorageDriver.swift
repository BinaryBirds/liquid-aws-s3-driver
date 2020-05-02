//
//  LiquidAwsS3StorageDriver.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

struct LiquidAwsS3StorageDriver: FileStorageDriver {
    let configuration: LiquidAwsS3StorageConfiguration

    func makeStorage(with context: FileStorageContext) -> FileStorage {
        LiquidAwsS3Storage(configuration: self.configuration, context: context)
    }
    
    func shutdown() {
        
    }
}
