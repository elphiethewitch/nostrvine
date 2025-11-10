//
//  LocationManager.swift
//  LibProofMode
//
//  Created by N-Pex on 2022-10-13.
//

import Foundation

//#if !PRIVACY_PROTECTED
import CoreMotion
import CoreLocation
//#endif

public class LocationManager: NSObject {

    public static let shared = LocationManager()

    private var isRequesting: Bool = false

    public class func emptyLocation() -> ProofCollection {
        let proof = ProofCollection()

        proof[.locationLatitude] = ""
        proof[.locationLongitude] = ""
        proof[.locationProvider] = "none"
        proof[.locationAccuracy] = ""
        proof[.locationAltitude] = ""
        proof[.locationBearing] = ""
        proof[.locationSpeed] = ""
        proof[.locationTime] = ""

        return proof
    }


    public func getLocation() -> ProofCollection {
        let proof = Self.emptyLocation()

#if !PRIVACY_PROTECTED

        let status = self.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return proof
        }

        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            self.semaphores.insert(semaphore)
            if !self.isRequesting {
                self.isRequesting = true
                self.cll.requestLocation()
            }
        }

        _ = semaphore.wait(timeout: .now().advanced(by: .seconds(60)))
        DispatchQueue.main.async {
            self.semaphores.remove(semaphore)
        }
        
        if let location = location {
            proof[.locationLatitude] = "\(location.coordinate.latitude)"
            proof[.locationLongitude] = "\(location.coordinate.longitude)"
            
            var provider = ""
            if #available(iOSApplicationExtension 14.0, *) {
                provider = [kCLLocationAccuracyReduced, kCLLocationAccuracyKilometer, kCLLocationAccuracyThreeKilometers].contains(location.horizontalAccuracy) ? "network" : "gps"
            } else {
                provider = [kCLLocationAccuracyKilometer, kCLLocationAccuracyThreeKilometers].contains(location.horizontalAccuracy) ? "network" : "gps"
            }
            if #available(iOSApplicationExtension 15.0, *) {
                if let source = location.sourceInformation {
                    if source.isSimulatedBySoftware {
                        provider = "simulated"
                    } else if source.isProducedByAccessory {
                        provider = "accessory"
                    }
                }
            }
            proof[.locationProvider] = provider
            // TODO - Android just has one accuracy value
            proof[.locationAccuracy] = "\(location.horizontalAccuracy),\(location.verticalAccuracy)"
            proof[.locationAltitude] = "\(location.altitude)"
            proof[.locationBearing] = "\(location.course)"
            proof[.locationSpeed] = "\(location.speed)"
            proof[.locationTime] = "\(location.timestamp.timeIntervalSince1970 * 1000)"
        }
#endif

        return proof
    }


#if !PRIVACY_PROTECTED
    public var location: CLLocation?

    private var semaphores: Set<DispatchSemaphore> = Set()

    private var authResultCallback: ((_ status: CLAuthorizationStatus) -> Void)?

    public lazy var cll: CLLocationManager = {
        var cll = CLLocationManager()
        cll.delegate = self

        return cll
    }()


    public var authorizationStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return cll.authorizationStatus
        }
        else {
            return CLLocationManager.authorizationStatus()
        }
    }


    public func getPermission(callback: @escaping (_ status: CLAuthorizationStatus) -> Void) {
        authResultCallback = callback

        cll.requestWhenInUseAuthorization()
    }
#endif
}

#if !PRIVACY_PROTECTED
extension LocationManager: CLLocationManagerDelegate {

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = authorizationStatus
        if let authResultCallback = authResultCallback {
            authResultCallback(status)
            self.authResultCallback = nil
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = cll.location
        semaphores.forEach { s in
            s.signal()
        }
        self.isRequesting = false
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.location = nil
        semaphores.forEach { s in
            s.signal()
        }
        self.isRequesting = false
    }
}
#endif
