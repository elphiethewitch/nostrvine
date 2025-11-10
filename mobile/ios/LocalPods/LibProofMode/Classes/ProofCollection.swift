//
//  Proofmode.swift
//  LibProofMode
//
//  Created by N-Pex on 2023-04-14.
//

/**
 Like an ordered `Dictionary`.
 */
public class ProofCollection: NSObject, Codable {

    public enum Key: String, CodingKey {
        case filePath = "File Path"
        case fileHashSha256 = "File Hash SHA256"
        case fileModified = "File Modified"
        case proofGenerated = "Proof Generated"
        case deviceId = "DeviceID"
        case deviceVendor = "DeviceID Vendor"
        case ipv4 = "IPv4"
        case ipv6 = "IPv6"
        case dataType = "DataType"
        case network = "Network"
        case networkType = "NetworkType"
        case hardware = "Hardware"
        case manufacturer = "Manufacturer"
        case screenSize = "ScreenSize"
        case language = "Language"
        case locale = "Locale"
        case locationLatitude = "Location.Latitude"
        case locationLongitude = "Location.Longitude"
        case locationProvider = "Location.Provider"
        case locationAccuracy = "Location.Accuracy"
        case locationAltitude = "Location.Altitude"
        case locationBearing = "Location.Bearing"
        case locationSpeed = "Location.Speed"
        case locationTime = "Location.Time"
        case cellInfo = "CellInfo"
    }


    var keys = [Key]()
    var values = [String?]()


    override init() {
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        super.init()

        let container = try decoder.container(keyedBy: Key.self)

        try container.allKeys.forEach { key in
            keys.append(key)
            values.append(try container.decode(String.self, forKey: key))
        }
    }


    public subscript(key: Key) -> String? {
        get {
            if let idx = keys.firstIndex(of: key) {
                return values[idx]
            }

            return nil
        }
        set(newValue) {
            if let idx = keys.firstIndex(of: key) {
                values[idx] = newValue
            }
            else {
                keys.append(key)
                values.append(newValue)
            }
        }
    }

    public func add(_ another: ProofCollection) {
        for i in 0 ..< another.keys.count {
            self[another.keys[i]] = another.values[i]
        }
    }

    public func toDict() -> [String: String] {
        Dictionary(uniqueKeysWithValues: zip(keys.map { $0.rawValue }, values.map { $0 ?? "" }))
    }



    // MARK: Encodable

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)

        for i in 0 ..< keys.count {
            let key = keys[i]
            let val = values[i] ?? ""
            try? container.encode(val as String, forKey: key)
        }
    }
}
