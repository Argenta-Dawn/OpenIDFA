//
// Created by Mengyu Li on 2020/8/19.
//

import Darwin.sys.sysctl
import Foundation
import Identify
#if os(iOS)
import CoreTelephony
import UIKit
#endif
import typealias CommonCrypto.CC_LONG
import func CommonCrypto.CC_MD5
import var CommonCrypto.CC_MD5_DIGEST_LENGTH

public enum IDFA {}

public extension IDFA {
    static func retrieve() throws -> Identification {
        try Identification(stable: stable(), unstable: unstable())
    }
}

private extension IDFA {
    static func stable() throws -> Identification.Stable {
        let systemVersionValue = systemVersion()
        let hardwareInfoValue = try hardwareInfo()
        let systemFileTimeValue = try systemFileTime()
        let diskValue = try disk()
        return Identification.Stable(
            systemVersion: systemVersionValue, hardwareInfo: hardwareInfoValue,
            systemFileTime: systemFileTimeValue, disk: diskValue
        )
    }

    static func unstable() throws -> Identification.Unstable {
        let systemBootTimeValue = try systemBootTime()
        let regionCodeValue = try regionCode()
        let languageCodeValue = try languageCode()
        let deviceNameValue = deviceName()
        return Identification.Unstable(
            systemBootTime: systemBootTimeValue, regionCode: regionCodeValue,
            languageCode: languageCodeValue, deviceName: deviceNameValue
        )
    }
}

extension IDFA {
    static func systemBootTime() throws -> Int {
        var mib = [CTL_KERN, KERN_BOOTTIME]
        var bootTime = timeval()
        var bootTimeSize = MemoryLayout<timeval>.size

        guard sysctl(&mib, UInt32(mib.count), &bootTime, &bootTimeSize, nil, 0) == 0 else {
            throw Error.systemBootTime
        }
        let second = bootTime.tv_sec / 10000
        return second
    }

    static func regionCode() throws -> String {
        guard let regionCode = Locale.current.regionCode else {
            throw Error.regionCode
        }
        return regionCode
    }

    static func languageCode() throws -> String {
        switch Locale.preferredLanguages.isEmpty {
        case true:
            guard let languageCode = Locale.current.languageCode else {
                throw Error.languageCode
            }
            return languageCode
        case false:
            guard let languageCode = Locale.preferredLanguages.first else {
                throw Error.languageCode
            }
            return languageCode
        }
    }

    static func deviceName() -> String {
        #if os(iOS)
        return UIDevice.current.name
        #else
        return ""
        #endif
    }

    static func systemVersion() -> String {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #else
        return ""
        #endif
    }

    static func hardwareInfo() throws -> String {
        let model = try systemControlByName(type: "hw.model")
        let machine = try systemControlByName(type: "hw.machine")
        let carrier = carrierInfo()
        let memory = try systemInfo(type: HW_PHYSMEM)
        return "\(model),\(machine),\(carrier),\(memory)"
    }

    static func systemFileTime() throws -> String {
        #if os(iOS) && !targetEnvironment(simulator)
        let path = "/private/var/mobile"
        #else
        let path = "/usr/bin"
        #endif
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        let creationDate = (attributes[.creationDate] as? Date) ?? Date(timeIntervalSince1970: 0)
        let modificationDate = (attributes[.modificationDate] as? Date) ?? Date(timeIntervalSince1970: 0)
        return "\(creationDate),\(modificationDate)"
    }

    static func disk() throws -> String {
        let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        let diskSize = (attributes[.systemSize] as? NSNumber)?.stringValue ?? ""
        return diskSize
    }
}

extension IDFA {
    static func systemControlByName(type: String) throws -> String {
        var size = 0
        guard sysctlbyname(type, nil, &size, nil, 0) == 0 else { throw Error.systemControl }
        let resultPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        defer { resultPointer.deallocate() }
        guard sysctlbyname(type, resultPointer, &size, nil, 0) == 0 else { throw Error.systemControl }
        let result = String(cString: resultPointer)
        return result
    }

    static func systemInfo(type: Int32) throws -> String {
        var mib = [CTL_HW, type]
        var result: Int32 = 0
        var size = MemoryLayout.size(ofValue: result)
        guard sysctl(&mib, u_int(mib.count), &result, &size, nil, 0) == 0 else { throw Error.systemControl }
        return "\(result)"
    }

    static func carrierInfo() -> String {
        #if os(iOS)
        let networkInfo = CTTelephonyNetworkInfo()

        func parseCarrier(carrier: CTCarrier) -> String {
            let carrierName = carrier.carrierName ?? ""
            let mobileCountryCode = carrier.mobileCountryCode ?? ""
            let mobileNetworkCode = carrier.mobileNetworkCode ?? ""
            return "\(carrierName)\(mobileCountryCode)\(mobileNetworkCode)"
        }

        if #available(iOS 12.0, *) {
            let carriers = networkInfo.serviceSubscriberCellularProviders?.sorted(by: {
                $0.key.localizedStandardCompare($1.key) == .orderedAscending
            }).reduce("") { (result, tuple) -> String in
                let (_, value) = tuple
                return result + parseCarrier(carrier: value)
            }
            return carriers ?? ""
        } else {
            guard let carrier = networkInfo.subscriberCellularProvider else {
                return ""
            }
            return parseCarrier(carrier: carrier)
        }
        #else
        return ""
        #endif
    }
}
