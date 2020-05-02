//
//  LiquidAwsS3StorageConfiguration.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

struct LiquidAwsS3StorageConfiguration: FileStorageConfiguration {
    let key: String
    let secret: String
    let bucket: String
    let region: Region
    let endpoint: String?
    
    func makeDriver(for databases: FileStorages) -> FileStorageDriver {
        return LiquidAwsS3StorageDriver(configuration: self)
    }
}

