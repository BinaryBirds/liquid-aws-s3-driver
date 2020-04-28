//
//  File.swift
//
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import Foundation
import LiquidKit
import AWSS3

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

