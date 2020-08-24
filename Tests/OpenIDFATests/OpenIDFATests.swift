@testable import OpenIDFA
import XCTest

final class OpenIDFATests: XCTestCase {
    func testHardwareModel() throws {
        let model = try IDFA.systemControlByName(type: "hw.model")
        print(model)
    }

    func testSystemFileTime() throws {
        let fileTime = try IDFA.systemFileTime()
        print(fileTime)
    }

    func testDisk() throws {
        let disk = try IDFA.disk()
        print(disk)
    }

    func testMD5() {
        let md5 = IDFA.md5(in: "IDFA")
        print(md5)
    }

    func testMD5_16() {
        let md5_16 = IDFA.MD5_16(in: "IDFA")
        print(md5_16)
    }

    func testIDFA() throws {
        let idfa = try IDFA.retrieve()
        print(idfa)
    }

    static var allTests = [
        ("testHardwareModel", testHardwareModel),
        ("testSystemFileTime", testSystemFileTime),
        ("testDisk", testDisk),
        ("testMD5", testMD5),
        ("testMD5_16", testMD5_16),
        ("testIDFA", testIDFA),
    ]
}
