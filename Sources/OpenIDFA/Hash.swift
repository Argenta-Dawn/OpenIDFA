//
// Created by Mengyu Li on 2020/11/11.
//

import Foundation
import typealias CommonCrypto.CC_LONG
import func CommonCrypto.CC_MD5
import var CommonCrypto.CC_MD5_DIGEST_LENGTH

enum Hash {}

extension Hash {
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

    static func merge(stableValue: String, unstableValue: String) -> String {
        let idfa = (stableValue + unstableValue).enumerated().reduce(into: "") { (result: inout String, tuple: (offset: Int, element: Character)) in
            if [8, 12, 16, 20].contains(tuple.offset) {
                result += "-"
            }
            result += String(tuple.element)
        }
        return idfa
    }
}
