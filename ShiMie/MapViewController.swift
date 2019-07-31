//
//  ViewController.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/6.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

// ✅ TODO: 手画定位点
// ✅ TODO: 进入一次自动定位，后面手动定位
// ✅ TODO: searchCenterPin被userLocationPin覆盖
// ✅ TODO: edit mode下无法跟随惯性滑动
// ✅ TODO: edit mode 缩放手势
// ✅ TODO: edit mode slider调整radius
// ✅ TODO：location manager 单例
// TODO: 添加进入Edit mode 动画
// TODO: MapView 类

class MapViewController: UIViewController, MAMapViewDelegate, CLLocationManagerDelegate, AMapSearchDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MAMapView!
    
    private var userLocationPin = CustomedAnnotation(with: .user)
    private var searchCenterPin = CustomedAnnotation(with: .searchCenter)
    private var searchCircle: MACircle! = MACircle(center: kCLLocationCoordinate2DInvalid, radius: CLLocationDistance(MapViewController.defaultSearchRadius))
    
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
        setupMapView(mapView)
        setupSlider(slider)
        setupLocateButton(locateButton)
        setupEditButton(editButton)
        LocationManager.shared.locate (at: kCLLocationAccuracyNearestTenMeters) { [weak self] (location) in
            self?.mapView.setCenter(location.coordinate, animated: true)
            self?.searchCircle.coordinate = location.coordinate
            self?.searchCenterPin.coordinate = location.coordinate
            self?.userLocationPin.coordinate = location.coordinate
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mapView.selectAnnotation(searchCenterPin, animated: false)
    }
    
    private var searchRadiusInPixels: CGFloat {
        let zoom = mapView.zoomLevel
        // TODO: 复杂计算可以用缓存
        // ref: https://zhuanlan.zhihu.com/p/33285173
        let scalePerPixel = 0.325 * pow(2, (19 - zoom))
        return CGFloat(searchCircle.radius) / scalePerPixel
    }
    
    private func handleModeChange(to mode: MapViewMode) {
        // TODO: 重构
        switch mode {
        case .normal:
            expandButtonView.expand = false
            editModeBannerView.isHidden = true
            mapView.setCenter(searchCenterPin.coordinate, animated: false)
        
        case .edit:
            expandButtonView.expand = true
            editModeBannerView.isHidden = false
            
            // reset radius
            let circleEdgePoint = mapView.convert(mapView.center.offset(dx: mapView.bounds.width * 0.8 * 0.5, dy: 0), toCoordinateFrom: mapView)
            let point1 = MAMapPointForCoordinate(circleEdgePoint)
            let point2 = MAMapPointForCoordinate(mapView.centerCoordinate)
            let radius = MAMetersBetweenMapPoints(point1, point2)
            searchCircle.radius = max(min(radius, CLLocationDistance(MapViewController.maxSearchRadius)), CLLocationDistance(MapViewController.minSearchRadius))
        }
        mapView.setCenter(searchCircle.coordinate, animated: false)
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
        mapView.showsCompass = false
        mapView.showsScale = true
        mapView.delegate = self
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        mapView.isRotateCameraEnabled = false
        mapView.minZoomLevel = 13.5
        mapView.maxZoomLevel = 17.2
        mapView.setZoomLevel(16.5, animated: true)
        
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
        mapView.add(searchCircle)
    }
    
    private func setupSlider(_ slider: UISlider) {
        slider.thumbTintColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        slider.minimumTrackTintColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        slider.minimumValue = 13.5
        slider.maximumValue = 17.2
        slider.value = Float(mapView.zoomLevel)
        expandButtonView.slider = slider
        slider.addTarget(self, action: #selector(sliderValueChange(_:)), for: .valueChanged)
    }
    
    @objc private func sliderValueChange(_ sender: Any) {
        if let slider = sender as? UISlider {
            if abs(mapView.zoomLevel - CGFloat(slider.value)) > 0.01 {
                zoomLevelRecord = mapView.zoomLevel
                mapView.setZoomLevel(CGFloat(slider.value), animated: true)
            }
        }
    }
    
    private func setupLocateButton(_ button: UIButton) {
        expandButtonView.upperButton = button
        button.setTitle("L", for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), for: .normal)
        button.addTarget(self, action: #selector(locate(_:)), for: .touchUpInside)
    }
    @objc private func locate(_ sender: Any) {
        print("click locate button")
        if mode == .edit {
            if let location = LocationManager.shared.lastLocation {
                mapView.setCenter(location.coordinate, animated: true)
                searchCircle.coordinate = location.coordinate
                searchCenterPin.coordinate = location.coordinate
                LocationManager.shared.locate (at: kCLLocationAccuracyNearestTenMeters)
            } else {
                LocationManager.shared.locate (at: kCLLocationAccuracyNearestTenMeters) { [weak self] (location) in
                    self?.mapView.setCenter(location.coordinate, animated: true)
                    self?.searchCircle.coordinate = location.coordinate
                    self?.searchCenterPin.coordinate = location.coordinate
                    self?.userLocationPin.coordinate = location.coordinate
                }
            }
        } else {
            if let location = LocationManager.shared.lastLocation {
                mapView.setCenter(location.coordinate, animated: false)
                LocationManager.shared.locate (at: kCLLocationAccuracyNearestTenMeters)
            } else {
                LocationManager.shared.locate (at: kCLLocationAccuracyNearestTenMeters) { [weak self] (location) in
                    self?.mapView.setCenter(location.coordinate, animated: true)
                    self?.userLocationPin.coordinate = location.coordinate
                }
            }
        }
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
    func mapViewRegionChanged(_ mapView: MAMapView!) {
        if mode == .edit {
            searchCircle.coordinate = mapView.centerCoordinate
            searchCenterPin.coordinate = mapView.centerCoordinate
            
            let deltaZoom = zoomLevelRecord - mapView.zoomLevel
            zoomLevelRecord = mapView.zoomLevel
            if mapView.zoomLevel <= 13.68 {
                searchCircle.radius = 2000
            } else if mapView.zoomLevel >= 17 {
                searchCircle.radius = 200
            } else if abs(deltaZoom) > 0.01 {
                searchCircle.radius = searchCircle.radius * Double(pow(2.0, deltaZoom))
                print("scale circle")
            }
            print("zoomLevel: \(mapView.zoomLevel), radius: \(searchCircle.radius)")
            slider.value = Float(mapView.zoomLevel)
        }
    }
    
    private var searchRadiusRecord: Double = 0
    private var zoomLevelRecord: CGFloat = 0
    func mapView(_ mapView: MAMapView!, mapWillZoomByUser wasUserAction: Bool) {
        if mode == .edit && wasUserAction {
            zoomLevelRecord = mapView.zoomLevel
        }
    }
    
    func mapView(_ mapView: MAMapView!, mapDidZoomByUser wasUserAction: Bool) {
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
        request.radius = Int(searchCircle.radius) / 2
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("did layout")
    }
}

extension MapViewController {
    static let searchCircleFillColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.4)
    static let searchCircleStrokeColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).withAlphaComponent(0.6)
    static let searchCircleStrokeLineWidth: CGFloat = 2.0
    static let maxSearchRadius = 2000
    static let minSearchRadius = 100
    static let defaultSearchRadius = 200
    
    enum MapViewMode {
        case normal
        case edit
    }
    
}

