//
//  ViewController.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/6.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

// TODO: 手画定位点 ✅
// TODO: 进入一次自动定位，后面手动定位 ✅
// TODO: editingCircle位置计算错误 ✅
// TODO: 添加进入Edit mode 动画
// TODO: Edit mode下searchCircle不能触发scroll手势

class MapViewController: UIViewController, MAMapViewDelegate, CLLocationManagerDelegate, AMapSearchDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MAMapView!
    private var locationManager = AMapLocationManager()
    
    private var searchRadius: Double = 200
    private var searchCenterPin = CustomedAnnotation(with: .searchCenter)
    private var searchCircle: MACircle? {
        didSet {
            if let oldValue = oldValue {
                mapView.remove(oldValue)
            }
            if let searchCircle = self.searchCircle {
                mapView.add(searchCircle)
            }
        }
    }
    lazy private var editingPin = { () -> UIView in
        let pinView = UIImageView(image: self.searchCenterPin.type.image)
        let view = UIView(frame: CGRect(origin: mapView.bounds.center.offset(dx: -pinView.bounds.width / 2, dy: -pinView.bounds.height), size: pinView.bounds.size))
        view.addSubview(pinView)
        view.addShadowSubview()
        view.isHidden = true
        mapView.addSubview(view)
        return view
    }()
    lazy private var editingCircle = { () -> UIView in
        let view = UIView()
        view.backgroundColor = MapViewController.searchCircleFillColor
        view.layer.borderColor = MapViewController.searchCircleStrokeColor.cgColor
        view.layer.borderWidth = MapViewController.searchCircleStrokeLineWidth
        view.layer.isHidden = true
        mapView.addSubview(view)
        return view
    }()
    
    private var userLocationPin = CustomedAnnotation(with: .user)
    
    private var restaurantPins = [MAAnnotation]()
    
    @IBOutlet weak var expandButtonView: ExpandButtonView!
    private var slider = UISlider()
    
    private var locateButton = UIButton()
    private var editButton = UIButton()
    
    @IBOutlet weak var editModeBannerView: UIStackView!
    
    private var mode = MapViewMode.normal {
        didSet {
            if self.mode != oldValue {
                handleModeChange(to: mode)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSlider(slider)
        setupMapView(mapView)
        setupLocateButton(locateButton)
        setupEditButton(editButton)
        locate(in: kCLLocationAccuracyNearestTenMeters, updateSearchPin: true)
    }
    
    private var searchRadiusInPixels: CGFloat {
        let zoom = mapView.zoomLevel
        // TODO: 复杂计算可以用缓存
        // ref: https://zhuanlan.zhihu.com/p/33285173
        let scalePerPixel = 0.325 * pow(2, (19 - zoom))
        return CGFloat(searchRadius) / scalePerPixel
    }
    
    private func handleModeChange(to mode: MapViewMode) {
        switch mode {
        case .normal:
            expandButtonView.expand = false
            editModeBannerView.isHidden = true
            editingCircle.isHidden = true
            searchCircle = MACircle(center: searchCenterPin.coordinate, radius: searchRadius)
            mapView.setCenter(searchCenterPin.coordinate, animated: false)
            
            searchCenterPin.view?.isHidden = false
            editingPin.isHidden = true
        case .edit:
            if searchCircle != nil {
                expandButtonView.expand = true
                editModeBannerView.isHidden = false
                mapView.setCenter(searchCircle!.coordinate, animated: false)
                let radius = searchRadiusInPixels
                let rect = CGRect(origin: mapView.bounds.center.offset(dx: -radius, dy: -radius), size: CGSize(width: radius * 2, height: radius * 2))
                editingCircle.frame = rect
                editingCircle.layer.cornerRadius = radius
                editingCircle.isHidden = false
                searchCircle = nil
                searchCenterPin.view?.isHidden = true
                editingPin.isHidden = false
            }
        }
    }
    @IBAction func cancelEditMode(_ sender: Any) {
        mode = .normal
    }
    @IBAction func confirmEditMode(_ sender: Any) {
        searchCenterPin.coordinate = mapView.centerCoordinate
        mode = .normal
    }
    
    private func setupMapView(_ mapView: MAMapView) {
        AMapServices.shared().enableHTTPS = true
        mapView.userTrackingMode = .none
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.delegate = self
        mapView.desiredAccuracy = 10
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
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
        
        mapView.addAnnotations([searchCenterPin, userLocationPin])
    }
    
    private func setupSlider(_ slider: UISlider) {
        let slider = UISlider()
        slider.thumbTintColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        slider.minimumTrackTintColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        slider.minimumValue = 100
        slider.maximumValue = 2000
        slider.value = Float(searchRadius)
        expandButtonView.slider = slider
        slider.addTarget(self, action: #selector(changeSearchRadius(_:)), for: .valueChanged)
    }
    
    private func setupLocateButton(_ button: UIButton) {
        expandButtonView.upperButton = button
        button.setTitle("L", for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), for: .normal)
        button.addTarget(self, action: #selector(locate(_:)), for: .touchUpInside)
    }
    @objc private func locate(_ sender: Any) {
        print("click locate button")
    }
    
    private func setupEditButton(_ button: UIButton) {
        expandButtonView.lowerButton = button
        button.setTitle("E", for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), for: .normal)
        button.addTarget(self, action: #selector(edit(_:)), for: .touchUpInside)
    }
    @objc private func edit(_ sender: Any) {
        print("click edit button")
        mode = .edit
    }
    
    // MARKER: Mapview Delegate
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

    // MARK: POI
    private var poiSearch = AMapSearchAPI()
    
    private func searchNearbyRestaurants(page: Int = 0) {
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
//                    annotations.append(p)
                }
            }
        }
    }
    
    @objc private func changeSearchRadius(_ sender: Any) {
        if let slider = sender as? UISlider {
            searchRadius = Double(slider.value)
        }
    }
    
    private func locate(in accuracy: CLLocationAccuracy =  kCLLocationAccuracyNearestTenMeters, updateSearchPin: Bool = false) {
        locationManager.desiredAccuracy = accuracy
        locationManager.locationTimeout = 1
        locationManager.locatingWithReGeocode = false
        locationManager.requestLocation(withReGeocode: false) { [weak self] (location, _, error) in
            if let error = error as NSError? {
                print("\(error.localizedDescription)")
                if error.code == AMapLocationErrorCode.locateFailed.rawValue {
                    print("\(error.localizedDescription)")
                } else {
                    
                }
            } else if let location = location, let self = self {
                self.userLocationPin.coordinate = location.coordinate
                self.mapView.setCenter(location.coordinate, animated: false)
                if updateSearchPin {
                    self.searchCenterPin.coordinate = location.coordinate
                    // TODO：重构
                    if self.mode == .normal {
                        self.searchCircle = MACircle(center: location.coordinate, radius: self.searchRadius)
                    }
                }
            }
        }
    }
    
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        if let annotation = annotation as? CustomedAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.type.identifier) ?? MAAnnotationView(annotation: annotation, reuseIdentifier: annotation.type.identifier)
            view?.image = annotation.type.image
            view?.centerOffset = annotation.type.centerOffset
            annotation.view = view
            return view
        }
        return nil
    }
}

extension MapViewController {
    static let searchCircleFillColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.4)
    static let searchCircleStrokeColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).withAlphaComponent(0.6)
    static let searchCircleStrokeLineWidth: CGFloat = 2.0
    static let maxSearchRadius = 2000
    static let minSearchRadius = 100
    
    enum MapViewMode {
        case normal
        case edit
    }
    
}

