//
//  File.swift
//  ShiMie
//
//  Created by 颜木林 on 2019/7/31.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import Foundation

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private var updateLocationCompletion: ((CLLocation) -> Void)?
    private var requestMemo: (CLLocationAccuracy, ((CLLocation) -> Void)?)?
    
    var authStatus: CLAuthorizationStatus
    { return CLLocationManager.authorizationStatus() }
    
    var lastLocation: CLLocationCoordinate2D? {
        didSet {
            if lastLocation != nil {
                UserDefaults.standard.set(lastLocation?.latitude, forKey: "userLocationLatitude")
                UserDefaults.standard.set(lastLocation?.longitude, forKey: "userLocationLongitude")
            }
        }
    }
    
    func locate(at accuracy: CLLocationAccuracy, with completion: ((_ location: CLLocation) -> Void)? = nil) {
        if authStatus != .authorizedWhenInUse && authStatus != .authorizedAlways {
            requestMemo = (accuracy, completion)
            locationManager.requestWhenInUseAuthorization()
        } else {
            updateLocationCompletion = completion
            locationManager.desiredAccuracy = accuracy
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last!.coordinate
        updateLocationCompletion?(locations.last!)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("\(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if authStatus == .denied {
            let alertVC = UIAlertController(title: "未打开定位权限", message: "请到设置中开启相应权限", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "确定", style: .default) { (_) in exit(1) }
            alertVC.addAction(confirmAction)
            UIApplication.shared.keyWindow?.rootViewController?.present(alertVC, animated: true)
        } else if status == .authorizedWhenInUse || status == .authorizedAlways, let requestMemo = requestMemo {
            locate(at: requestMemo.0, with: requestMemo.1)
            self.requestMemo = nil
        }
    }
    
    private var locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        let lat = UserDefaults.standard.double(forKey: "userLocaitonLatitude")
        let lng = UserDefaults.standard.double(forKey: "userLocaitonLongitude")
        lastLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        locationManager.delegate = self
    }
}
