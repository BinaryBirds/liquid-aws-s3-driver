//
//  S3Bucket+Extensions.swift
//  LiquidAwsS3Driver
//
//  Created by Tibor Bodecs on 2020. 08. 21..
//

import Foundation

extension S3.Bucket: ExpressibleByStringLiteral {

    /// Create a Bucket object using a String literal
    public init(stringLiteral value: String) {
        self = .init(name: value)
    }
}

extension S3.Bucket {

    ///
    /// Simple bucket name validator
    ///
    /// Rules based on [Bucket restrictions and limitations](https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html)
    ///
    /// - Note:
    ///     This method does not account for the rule disallowing IP Addresses, nor does it check uniqueness or other special cases
    ///
    public func hasValidName() -> Bool {
        let validStartEnd = CharacterSet.lowercaseLetters.union(.decimalDigits)
        let valid = validStartEnd.union(CharacterSet(charactersIn: ".-"))

        guard
            let name = name,
            name.count >= 3,
            name.count <= 63,
            name.unicodeScalars.allSatisfy({ valid.contains($0) }),
            let first = name.first,
            first.unicodeScalars.allSatisfy({ validStartEnd.contains($0) }),
            let last = name.last,
            last.unicodeScalars.allSatisfy({ validStartEnd.contains($0) })
        else {
            return false
        }
        return true
    }
}

