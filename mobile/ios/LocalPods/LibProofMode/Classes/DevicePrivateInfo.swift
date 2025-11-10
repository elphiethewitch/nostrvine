//
//  DevicePrivateInfo.swift
//  LibProofMode
//
//  Created by N-Pex on 2023-02-10.
//
// Information that might contain private information, e.g. the device ad identifier


#if !PRIVACY_PROTECTED
import AdSupport
import CryptoKit
#endif

class DevicePrivateInfo {
    public static func getDeviceId() -> String {
#if PRIVACY_PROTECTED
        return ""
#else
        let uuid = ASIdentifierManager.shared().advertisingIdentifier
        let md5 = Insecure.MD5.hash(data: uuid.uuidString.data(using: .utf8)!)
        let val = abs(md5.hashValue)
        return String(val, radix: 36, uppercase: false)
#endif
    }
}

