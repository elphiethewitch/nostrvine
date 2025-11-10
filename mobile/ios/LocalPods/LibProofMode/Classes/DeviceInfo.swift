//
//  DeviceInfo.swift
//  LibProofMode
//
//  Created by N-Pex on 2020-07-22.
//

import UIKit
import CoreTelephony
import CryptoKit
import DeviceKit


class DeviceInfo {
   
    public static func getVendorIdentifier() -> String {
        if let uuid = UIDevice.current.identifierForVendor {
            let md5 = Insecure.MD5.hash(data: uuid.uuidString.data(using: .utf8)!)
            let val = abs(md5.hashValue)
            return String(val, radix: 36, uppercase: false)
        }
        return ""
    }
    
    public static func getDeviceInfo(device:Device) -> String? {
        switch device {
        case .DEVICE_IP_ADDRESS_IPV4:
            return getIP(false)
        case .DEVICE_IP_ADDRESS_IPV6:
            return getIP(true)
        case .DEVICE_DATA_TYPE:
            return getDataType()
        case .DEVICE_NETWORK:
            return getNetwork()
        case .DEVICE_NETWORK_TYPE:
            return getNetworkType()
        case .DEVICE_HARDWARE_MODEL:
            return getHardwareModel()
        case .DEVICE_SCREEN_SIZE:
            return screenSize()
        case .DEVICE_LANGUAGE:
            if #available(iOS 16, *) {
                return Locale.current.language.languageCode?.identifier
            } else {
                return Locale.current.languageCode
            }
        case .DEVICE_LOCALE:
            if #available(iOS 16, *) {
                return Locale.current.region?.identifier ?? ""
            } else {
                return Locale.current.regionCode
            }
        case .DEVICE_CELL_INFO:
            return cellInfo()
        default:
            return nil
        }
    }
    
    // Adapted from https://stackoverflow.com/questions/44541280/get-ipaddress-of-iphone-or-ipad-device-using-swift-3/44542228
    private static func getIP(_ v6:Bool) -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next } // memory has been renamed to pointee in swift 3 so changed memory to pointee
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(v6 ? AF_INET6 : AF_INET) {
                    if let cname = interface?.ifa_name, String(cString: cname) == "en0" {  // String.fromCString() is deprecated in Swift 3. So use the following code inorder to get the exact IP Address.
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                    
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
    
    private static func getDataType()->String {
        let networkInfo = CTTelephonyNetworkInfo()
        if let carrierType = networkInfo.serviceCurrentRadioAccessTechnology, carrierType.count > 0 {
            print("Carrier types \(carrierType)")
            return carrierType.values.first ?? ""
        }
        return ""
    }
    
    private static func getNetwork() -> String {
        let net = NetworkStatus.shared
        net.start() // Internet connection monitoring starts
        net.stop() // Internet connection monitoring stops
        let status = net.connType
        if status == .cellular || status == .ethernet || status == .wifi {
            return "Connected"
        } else {
            return "0"
        }
    }
    
    private static func getNetworkType() -> String {
        let net = NetworkStatus.shared
        net.start() // Internet connection monitoring starts
        net.stop() // Internet connection monitoring stops
        let status = net.connType
        switch status {
        case .wifi:
            return "Wifi"
        case .ethernet:
            return "Ethernet"
        case .cellular:
            return getDataType()
        default: return "noNetwork"
        }
    }
    
    private static func getHardwareModel() -> String {
        return DeviceKit.Device.current.model ?? ""
    }

    private static func screenSize() -> String {
        return "\(DeviceKit.Device.current.diagonal)"
        
    }
    
    private static func cellInfo() -> String {
        // TODO - Not sure what to return here
        let networkInfo = CTTelephonyNetworkInfo()
        let carrierTypes = networkInfo.serviceCurrentRadioAccessTechnology ?? [:]
        return carrierTypes.keys.joined(separator: ",")
    }
    
    public enum Device {
        case DEVICE_TYPE, DEVICE_SYSTEM_NAME, DEVICE_VERSION, DEVICE_SYSTEM_VERSION, DEVICE_TOKEN,
            
        /**
         *
         */
        DEVICE_NAME, DEVICE_UUID, DEVICE_MANUFACTURE, IPHONE_TYPE,
        /**
         *
         */
        CONTACT_ID, DEVICE_LANGUAGE, DEVICE_TIME_ZONE, DEVICE_LOCAL_COUNTRY_CODE,
        /**
         *
         */
        DEVICE_CURRENT_YEAR, DEVICE_CURRENT_DATE_TIME, DEVICE_CURRENT_DATE_TIME_ZERO_GMT,
        /**
         *
         */
        DEVICE_HARDWARE_MODEL, DEVICE_NUMBER_OF_PROCESSORS, DEVICE_LOCALE, DEVICE_NETWORK, DEVICE_NETWORK_TYPE,
        /**
         *
         */
        DEVICE_IP_ADDRESS_IPV4, DEVICE_IP_ADDRESS_IPV6, DEVICE_MAC_ADDRESS, DEVICE_TOTAL_CPU_USAGE,
        /**
         *
         */
        DEVICE_TOTAL_MEMORY, DEVICE_FREE_MEMORY, DEVICE_USED_MEMORY,
        /**
         *
         */
        DEVICE_TOTAL_CPU_USAGE_USER, DEVICE_TOTAL_CPU_USAGE_SYSTEM,
        /**
         *
         */
        DEVICE_TOTAL_CPU_IDLE, DEVICE_IN_INCH,
        
        DEVICE_DATA_TYPE,
             
        DEVICE_SCREEN_SIZE,
        DEVICE_CELL_INFO
        ;
    }
}
