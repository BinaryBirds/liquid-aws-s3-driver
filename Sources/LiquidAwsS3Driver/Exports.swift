//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

@_exported import LiquidKit
@_exported import enum AWSS3.Region

public extension FileStorageID {
    static var awsS3: FileStorageID { .init(string: "aws-s3") }
}
