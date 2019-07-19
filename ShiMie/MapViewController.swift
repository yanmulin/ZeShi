//
//  ViewController.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/6.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

class MapViewController: UIViewController, MAMapViewDelegate, CLLocationManagerDelegate, AMapSearchDelegate, UIGestureRecognizerDelegate {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        slider.value = Float(searchRadius)
        setMapZoomLevel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARKER: map related
    @IBOutlet weak var mapView: MAMapView! {
        didSet {
            AMapServices.shared().enableHTTPS = true
            mapView.userTrackingMode = .follow
            mapView.showsCompass = false
            mapView.showsScale = false
            mapView.delegate = self
            mapView.desiredAccuracy = 10
//            mapView.isScrollEnabled = false
            mapView.isZoomEnabled = false
            mapView.isRotateCameraEnabled = false
            
            // 自定义地图样式
            if let path = Bundle.main.path(forResource: "AmapStyle", ofType: "bundle"), let mapStyleBundle = Bundle.init(path: path), let dataPath = mapStyleBundle.path(forResource: "style", ofType: "data"), let extraPath = mapStyleBundle.path(forResource: "style_extra", ofType: "data") {
                let styleOption = MAMapCustomStyleOptions.init()
                let dataUrl = URL(fileURLWithPath: dataPath)
                assert (try! dataUrl.checkResourceIsReachable())
                let extraUrl = URL(fileURLWithPath: extraPath)
                styleOption.styleData = try? Data(contentsOf: dataUrl)
                styleOption.styleExtraData = try? Data(contentsOf: extraUrl)
                mapView.setCustomMapStyleOptions(styleOption)
                mapView.customMapStyleEnabled = true
            }
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
            pan.delegate = self
            mapView.addGestureRecognizer(pan)
            
            let r = MAUserLocationRepresentation()
            r.showsAccuracyRing = false
            mapView.update(r)
        }
    }
    
    @objc func pan(_ gr: UIPanGestureRecognizer) {
        switch gr.state {
        case .began: break
        case .changed: moveCircle(to: mapView.center);
        case .ended, .cancelled: break
        default: break
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MAMapView!, mapDidMoveByUser wasUserAction: Bool) {
        isCircleMoving = false
    }
    
    private var radiusStep = 100.0
    private var searchRadius: Double = 200 {// unit:m
        didSet { setMapZoomLevel() }
    }
    
    private var zoomLevels: [Int: Double] = {
        var zoomLevels = [Int: Double]()
        for x in stride(from: 100, to: 2000, by: 100) {
            let dx = 1/Double(x)
            let subexp1 = 1.787e+07 * dx - 3.298e+05
            let subexp2 = subexp1 * dx + 2001
            zoomLevels[x] = subexp2 * dx + 12.4
        }
        return zoomLevels
    }()
    
    private func setMapZoomLevel() {
        if let level = zoomLevels[Int(searchRadius/radiusStep) * 100] {
            mapView.setZoomLevel(CGFloat(level), animated: true)
        }
    }
    
    @IBAction func seach(_ sender: Any) {
        searchNearbyRestaurants()
    }
    
    private var fixedCircle: MAOverlay?
    private var isCircleMoving: Bool = false {
        didSet {
            if oldValue != self.isCircleMoving {
                if self.isCircleMoving == false {
                    fixedCircle = MACircle(center: mapView.centerCoordinate, radius: searchRadius)
                    mapView.add(fixedCircle)
                    mapView.removeAnnotations(annotations)
                } else {
                    mapView.remove(fixedCircle)
                }
            }
        }
    }
    lazy private var movingCircle = { () -> CALayer in
        let movingCircle = CALayer()
        //        movingCircle.backgroundColor = MapViewController.searchCircleFillColor.cgColor
        movingCircle.backgroundColor = MapViewController.searchCircleFillColor.cgColor
        movingCircle.borderColor = MapViewController.searchCircleStrokeColor.cgColor
        movingCircle.borderWidth = MapViewController.searchCircleStrokeLineWidth / 2
        view.layer.addSublayer(movingCircle)
        return movingCircle
    }()
    
    func moveCircle(to center: CGPoint) {
        isCircleMoving = true
        let radius =  CGFloat(slider.value) / CGFloat(mapView.metersPerPointForCurrentZoom)//mapView.metersPerPointForCurrentZoomLevel
        movingCircle.cornerRadius = radius
        movingCircle.frame = CGRect(origin: center.offset(dx: -radius, dy: -radius), size: CGSize.init(width: radius*2, height: radius*2))
        movingCircle.isHidden = false
    }
    
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if overlay.isKind(of: MACircle.self) {
            let renderer: MACircleRenderer = MACircleRenderer(overlay: overlay)
            renderer.lineWidth = MapViewController.searchCircleStrokeLineWidth
            renderer.strokeColor = MapViewController.searchCircleStrokeColor
            renderer.fillColor = MapViewController.searchCircleFillColor
            return renderer
        }
        return nil
    }
    
    func mapView(_ mapView: MAMapView!, didAddOverlayRenderers renderers: [Any]!) {
        if let renderer = renderers.first, (renderer as AnyObject).isKind(of: MACircleRenderer.self) {
            self.movingCircle.isHidden = true
        }
    }
    
    
    private var isFirstUpdate = true
    func mapView(_ mapView: MAMapView!, didUpdate userLocation: MAUserLocation!, updatingLocation: Bool) {
        if isFirstUpdate {
            isCircleMoving = false
            searchNearbyRestaurants()
            isFirstUpdate = false
        }
    }

    private var annotations = [MAAnnotation]()
    
    // MARK: POI
    private var poiSearch = AMapSearchAPI()
    
    private func searchNearbyRestaurants(page: Int = 0) {
        if page == 0 {
            annotations.removeAll()
        }
        print("request page#\(page)")
        let request = AMapPOIAroundSearchRequest()
        let coordinate = mapView.centerCoordinate
        request.location = AMapGeoPoint.location(withLatitude: CGFloat(coordinate.latitude), longitude: CGFloat(coordinate.longitude))
        request.sortrule = 0
        request.offset = 50
        request.page = page
        request.radius = Int(searchRadius) / 2
        request.types = "餐饮服务"
        request.requireExtension = true
        poiSearch?.delegate = self
        poiSearch?.aMapPOIAroundSearch(request)
    }
    
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        if response.count == 0 {
            return
        }
        print("pois count: \(response.count), page count: \(response.pois.count)")
        if request.isKind(of: AMapPOIAroundSearchRequest.self) {
            response.pois.forEach {
                if let latitude = $0.location?.latitude, let longitude = $0.location?.longitude {
                    let p=MAPointAnnotation()
                    p.coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(latitude), CLLocationDegrees(longitude))
                    p.title = $0.name
                    p.subtitle = $0.address
//                    print("{\n\tname: \($0.name), \n\ttel: \($0.tel), \n\taddress:\($0.address), \n\timages: \($0.images), \n\taverage-cost: \($0.extensionInfo.cost), \n\trating:\($0.extensionInfo.rating), \n\topenTime:\($0.extensionInfo.openTime), \n\ttype: \($0.type)\n}")
                    annotations.append(p)
                }
            }
            print("annotations count:\(annotations.count)")
            if annotations.count < response.count {
                searchNearbyRestaurants(page: annotations.count / 50)
            } else {
                mapView.addAnnotations(annotations)
            }
        }
    }
    
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        if annotation.isKind(of: MAPointAnnotation.self) {
            let pointReuseIndetifier = "pointReuseIndetifier"
            var annotationView: MAPinAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier) as! MAPinAnnotationView?
            
            if annotationView == nil {
                annotationView = MAPinAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
            }
            
            annotationView!.canShowCallout = true
            annotationView!.animatesDrop = true
            annotationView!.isDraggable = true
            annotationView!.rightCalloutAccessoryView = UIButton(type: UIButton.ButtonType.detailDisclosure)
            
            return annotationView!
        }
        
        return nil
    }
    
    //MAKER: upper right widget
    @IBOutlet weak var expandButtonView: ExpandButtonView!
    lazy private var slider = makeSlider()
    
    private func makeSlider() -> UISlider {
        let slider = UISlider()
        slider.thumbTintColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        slider.minimumTrackTintColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        slider.minimumValue = 100
        slider.maximumValue = 2000
        slider.value = slider.minimumValue
        expandButtonView.slider = slider
        slider.addTarget(self, action: #selector(changeSearchRadius(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(didEndEditSearchRadius(_:)), for: .touchUpInside)
        return slider
    }
    
    @objc private func changeSearchRadius(_ sender: Any) {
        if let slider = sender as? UISlider {
            if Int(searchRadius / radiusStep) != Int(Double(slider.value) / radiusStep) {
                searchRadius = Double(slider.value)
            }
            moveCircle(to: mapView.center)
        }
    }
    
    @objc private func didEndEditSearchRadius(_ sender: Any) {
        if let slider = sender as? UISlider {
            searchRadius = Double(slider.value)
            isCircleMoving = false
        }
    }
    
}

extension MapViewController {
    static let searchCircleFillColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.4)
    static let searchCircleStrokeColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).withAlphaComponent(0.6)
    static let searchCircleStrokeLineWidth: CGFloat = 4.0
    
}

