import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(LiquidAwsS3DriverTests.allTests),
    ]
}
#endif
