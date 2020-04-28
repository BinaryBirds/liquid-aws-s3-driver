import Foundation
import LiquidKit
import NIO
import AWSS3

struct LiquidAwsS3StorageDriver: FileStorageDriver {
    let configuration: LiquidAwsS3StorageConfiguration

    func makeStorage(with context: FileStorageContext) -> FileStorage {
        LiquidAwsS3Storage(configuration: self.configuration, context: context)
    }
    
    func shutdown() {
        
    }
}
