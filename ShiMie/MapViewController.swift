//
//  ViewController.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/6.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

class MapViewController: UIViewController, MAMapViewDelegate, CLLocationManagerDelegate, AMapSearchDelegate {
    
    private var searchRadius = 200 // unit:m
    
    private var mapView:MAMapView!
    private var poiSearch = AMapSearchAPI()
    private var clmanager = CLLocationManager() {
        didSet {
            clmanager.delegate = self
            clmanager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            clmanager.distanceFilter = 100
            clmanager.startUpdatingLocation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AMapServices.shared().enableHTTPS = true
        mapView = MAMapView(frame: view.bounds)
        mapView.isShowsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
        mapView.setZoomLevel(14.0, animated: true)
        view.addSubview(mapView)
        
        poiSearch?.delegate = self
        
        searchNearbyRestaurants()
    }
    
    private func searchNearbyRestaurants() {
        if let coordinate = clmanager.location?.coordinate {
            let request = AMapPOIAroundSearchRequest()
            
            request.location = AMapGeoPoint.location(withLatitude: CGFloat(coordinate.latitude), longitude: CGFloat(coordinate.longitude))
            request.sortrule = 0
            request.radius = searchRadius
            request.types = "餐饮服务"
            request.requireExtension = true
            poiSearch?.aMapPOIAroundSearch(request)
        }
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("update locations: \(locations)")
    }

    // MARK: AMapSearchDelegate
    
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        if response.count == 0 {
            return
        }
        print("\(response.count)")
        if request.isKind(of: AMapPOIAroundSearchRequest.self) {
            var annotations = [MAPointAnnotation]()
            response.pois.forEach {
                if let latitude = $0.location?.latitude, let longitude = $0.location?.longitude {
                    let p=MAPointAnnotation()
                    p.coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(latitude), CLLocationDegrees(longitude))
                    p.title = $0.name
                    print("{\n\tname: \($0.name), \n\ttel: \($0.tel), \n\taddress:\($0.address), \n\timages: \($0.images), \n\taverage-cost: \($0.extensionInfo.cost), \n\trating:\($0.extensionInfo.rating), \n\topenTime:\($0.extensionInfo.openTime), \n\ttype: \($0.type)\n}")
                    annotations.append(p)
                }
            }
            mapView.addAnnotations(annotations)
        }
    }
}

