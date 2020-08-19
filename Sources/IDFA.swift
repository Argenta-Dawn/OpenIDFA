//
// Created by Mengyu Li on 2020/8/19.
//

import Darwin.sys.sysctl
import Foundation
#if os(iOS)
import CoreTelephony
import UIKit
#endif
import typealias CommonCrypto.CC_LONG
import func CommonCrypto.CC_MD5
import var CommonCrypto.CC_MD5_DIGEST_LENGTH

public struct IDFA { private init() {} }

public extension IDFA {
	static func retrieve() throws -> String {
		let fingerPrintStablePart = "\(systemVersion()),\(try hardwareInfo()),\(try systemFileTime()),\(try disk())"
		let fingerPrintUnstablePart = "\(try systemBootTime()),\(try regionCode()),\(try languageCode()),\(deviceName())"

		let fingerPrintStablePartMD5_16 = MD5_16(in: fingerPrintStablePart)
		let fingerPrintUnstablePartMD5_16 = MD5_16(in: fingerPrintUnstablePart)
		let idfa = (fingerPrintStablePartMD5_16 + fingerPrintUnstablePartMD5_16).enumerated().reduce(into: "") { (result: inout String, tuple: (offset: Int, element: Character)) in
			if [8, 12, 16, 20].contains(tuple.offset) {
				result += "-"
			}
			result += String(tuple.element)
		}
		return idfa
	}
}

// MARK: - MD5

extension IDFA {
	static func md5(in: String) -> String {
		let length = Int(CC_MD5_DIGEST_LENGTH)
		let messageData = `in`.data(using: .utf8)!
		var digestData = Data(count: length)

		digestData.withUnsafeMutableBytes { digestBytes -> Void in
			messageData.withUnsafeBytes { messageBytes -> Void in
				if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
					let messageLength = CC_LONG(messageData.count)
					CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
				}
			}
		}
		return digestData.map { String(format: "%02hhX", $0) }.joined()
	}

	static func MD5_16(in: String) -> String {
		let md5String = md5(in: `in`)
		let startIndex = md5String.index(md5String.startIndex, offsetBy: 8)
		let endIndex = md5String.index(md5String.endIndex, offsetBy: -8)
		let result = md5String[startIndex..<endIndex]
		return String(result)
	}
}

extension IDFA {
	static func systemBootTime() throws -> String {
		var mib = [CTL_KERN, KERN_BOOTTIME]
		var bootTime = timeval()
		var bootTimeSize = MemoryLayout<timeval>.size

		guard sysctl(&mib, UInt32(mib.count), &bootTime, &bootTimeSize, nil, 0) == 0 else {
			throw Error.systemBootTime
		}
		let second = bootTime.tv_sec / 10000
		return "\(second)"
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

	static func systemVersion() -> String {
		#if os(iOS)
		return UIDevice.current.systemVersion
		#else
		return ""
		#endif
	}

	static func deviceName() -> String {
		#if os(iOS)
		return UIDevice.current.name
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
		let attributes = try FileManager.default.attributesOfItem(atPath: "/System/Library/CoreServices")
		let creationDate = (attributes[.creationDate] as? Date) ?? Date(timeIntervalSince1970: 0)
		let modificationDate = (attributes[.modificationDate] as? Date) ?? Date(timeIntervalSince1970: 0)
		return "\(creationDate),\(modificationDate)"
	}

	static func disk() throws -> String {
		let attributes = try FileManager.default.attributesOfItem(atPath: FileManager.default.currentDirectoryPath)
		let diskSize = (attributes[.systemSize] as? String) ?? ""
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
		guard let carrier = networkInfo.subscriberCellularProvider else {
			return ""
		}
		let carrierName = carrier.carrierName ?? ""
		let mobileCountryCode = carrier.mobileCountryCode ?? ""
		let mobileNetworkCode = carrier.mobileNetworkCode ?? ""
		return "\(carrierName)\(mobileCountryCode)\(mobileNetworkCode)"
		#else
		return ""
		#endif
	}
}