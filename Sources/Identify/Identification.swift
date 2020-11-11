//
// Created by Mengyu Li on 2020/11/11.
//

public struct Identification: Codable {
    public let value: String
    public let stable: Stable
    public let unstable: Unstable

    public init(stable: Stable, unstable: Unstable) {
        self.stable = stable
        self.unstable = unstable
        value = Hash.merge(stableValue: stable.value, unstableValue: unstable.value)
    }
}

extension Identification {
    public struct Stable: Codable {
        public let value: String

        public let systemVersion: String
        public let hardwareInfo: String
        public let systemFileTime: String
        public let disk: String

        public init(systemVersion: String, hardwareInfo: String, systemFileTime: String, disk: String) {
            self.systemVersion = systemVersion
            self.hardwareInfo = hardwareInfo
            self.systemFileTime = systemFileTime
            self.disk = disk
            value = Hash.MD5_16(in: "\(systemVersion),\(hardwareInfo),\(systemFileTime),\(disk)")
        }
    }
}

extension Identification {
    public struct Unstable: Codable {
        public let value: String

        public let systemBootTime: Int
        public let regionCode: String
        public let languageCode: String
        public let deviceName: String

        public init(systemBootTime: Int, regionCode: String, languageCode: String, deviceName: String) {
            self.systemBootTime = systemBootTime
            self.regionCode = regionCode
            self.languageCode = languageCode
            self.deviceName = deviceName
            value = Hash.MD5_16(in: "\(systemBootTime),\(regionCode),\(languageCode),\(deviceName)")
        }
    }
}
