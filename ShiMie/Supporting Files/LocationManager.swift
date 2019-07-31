//
//  File.swift
//  ShiMie
//
//  Created by 颜木林 on 2019/7/31.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import Foundation

class LocationManager {
    static let shared = LocationManager()
    
    var lastLocation: CLLocation?
    
    func locate(at accuracy: CLLocationAccuracy, with completion: ((_ location: CLLocation) -> Void)? = nil) {
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.locationTimeout = 1
        locationManager.locatingWithReGeocode = false
        locationManager.requestLocation(withReGeocode: false) { [weak self] (location, _, error) in
            if let error = error as NSError? {
                print("\(error.localizedDescription)")
                if error.code == AMapLocationErrorCode.locateFailed.rawValue {
                    print("\(error.localizedDescription)")
                } else {
                    
                }
            } else if let location = location {
                self?.lastLocation = location
                completion?(location)
            }
        }
    }
    
    private var locationManager = AMapLocationManager()
    
    private init() {}
}
