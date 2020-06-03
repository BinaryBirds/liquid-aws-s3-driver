//
//  LiquidAwsS3StorageConfiguration.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//
import Foundation

struct LiquidAwsS3StorageConfiguration: FileStorageConfiguration {
    enum S3ConfigurationError: Error {
        case invalidBucketName
    }

    let key: String
    let secret: String
    let bucket: String
    let region: Region
    let endpoint: String?

    init(key: String, secret: String, bucket: String, region: Region, endpoint: String?) throws {
        guard Self.validate(bucketName: bucket) else {
            throw S3ConfigurationError.invalidBucketName
        }
        self.key = key
        self.secret = secret
        self.bucket = bucket
        self.region = region
        self.endpoint = endpoint
    }

    /// Validates bucket naming rules based on https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html
    /// note this does not account for the rule disallowing IP Addresses, nor does it check uniqueness or other special cases
    private static func validate(bucketName: String) -> Bool {
        let legalBucketStartAndFinishCharacterSet: CharacterSet = CharacterSet.lowercaseLetters
            .union(.decimalDigits)
        let legalBucketCharacterSet: CharacterSet = legalBucketStartAndFinishCharacterSet.union(CharacterSet(charactersIn: ".-"))

        guard bucketName.count >= 3,
            bucketName.count <= 63,
            bucketName.unicodeScalars.allSatisfy({ legalBucketCharacterSet.contains($0) }),
            let first = bucketName.first,
            first.unicodeScalars.allSatisfy({ legalBucketStartAndFinishCharacterSet.contains($0) }),
            let last = bucketName.last,
            last.unicodeScalars.allSatisfy({ legalBucketStartAndFinishCharacterSet.contains($0) })
            else { return false }
        return true
    }
    
    func makeDriver(for databases: FileStorages) -> FileStorageDriver {
        return LiquidAwsS3StorageDriver(configuration: self)
    }
}

