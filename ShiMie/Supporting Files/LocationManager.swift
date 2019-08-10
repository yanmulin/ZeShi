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
    
    var lastLocation: CLLocationCoordinate2D? {
        didSet {
            if lastLocation != nil {
                UserDefaults.standard.set(lastLocation?.latitude, forKey: "userLocationLatitude")
                UserDefaults.standard.set(lastLocation?.longitude, forKey: "userLocationLongitude")
            }
        }
    }
    
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
                self?.lastLocation = location.coordinate
                completion?(location)
            }
        }
    }
    
    private var locationManager = AMapLocationManager()
    
    private init() {
        let lat = UserDefaults.standard.double(forKey: "userLocaitonLatitude")
        let lng = UserDefaults.standard.double(forKey: "userLocaitonLongitude")
        lastLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}
