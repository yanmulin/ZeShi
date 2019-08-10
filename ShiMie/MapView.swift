//
//  MapView.swift
//  ShiMie
//
//  Created by 颜木林 on 2019/7/31.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

class MapView: MAMapView, MAMapViewDelegate {
    
    var firstLoadCompletion: (()->Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupMapView()
        addSubview(loadingIndicator)
        loadingIndicator.startAnimating()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        loadingIndicator.center = bounds.center
    }
    
    var mode = MapViewMode.normal {
        didSet {
            if self.mode != oldValue {
                handleModeChange(to: mode)
            }
        }
    }
    
    private func handleModeChange(to mode: MapViewMode) {
        setCenter(searchCenterPin.coordinate, animated: false)
        switch mode {
        case .normal:
            setCenter(searchCenterPin.coordinate, animated: false)
            if let view = searchCenterPin.view?.imageView {
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.25,
                                                               delay: 0.0,
                                                               options: .curveEaseIn,
                                                               animations: {
                                                                view.center.y += 50
                })
            }
            
        case .edit:

            let circleScreenRect = convertRegion(MACoordinateRegionForMapRect(searchCircle.boundingMapRect), toRectTo: self)
            let zoomDelta = log(circleScreenRect.width / (bounds.width *  MapViewController.defualtScreenCircleRatio))
            setZoomLevel(zoomLevel - zoomDelta, animated: false)
            
            if let view = searchCenterPin.view?.imageView {
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.25,
                                                               delay: 0.0,
                                                               options: .curveEaseInOut,
                                                               animations: {
                                                                view.center.y -= 50
                })
            }
        }
        
    }

    
 

    var userLocationPin = CustomedAnnotation(with: .user)
    var searchCenterPin = CustomedAnnotation(with: .searchCenter)
    var searchCircle: MACircle! = MACircle(center: kCLLocationCoordinate2DInvalid, radius: MapViewController.defaultSearchRadius)
    
    private func setupMapView() {
        AMapServices.shared().enableHTTPS = true
        showsCompass = false
        showsScale = false
        delegate = self
        isScrollEnabled = true
        isZoomEnabled = true
        isRotateCameraEnabled = false
        minZoomLevel = MapViewController.minZoomLevel
        maxZoomLevel = MapViewController.maxZoomLevel
        setZoomLevel(MapViewController.defaultZoomLevel, animated: false)
        if let coordinate = LocationManager.shared.lastLocation {
            setCenter(coordinate , animated: false)
        }
        
        // 自定义地图样式
        if let path = Bundle.main.path(forResource: "AmapStyle", ofType: "bundle"), let mapStyleBundle = Bundle.init(path: path), let dataPath = mapStyleBundle.path(forResource: "style", ofType: "data"), let extraPath = mapStyleBundle.path(forResource: "style_extra", ofType: "data") {
            let styleOption = MAMapCustomStyleOptions.init()
            let dataUrl = URL(fileURLWithPath: dataPath)
            assert (try! dataUrl.checkResourceIsReachable())
            let extraUrl = URL(fileURLWithPath: extraPath)
            styleOption.styleData = try? Data(contentsOf: dataUrl)
            styleOption.styleExtraData = try? Data(contentsOf: extraUrl)
            setCustomMapStyleOptions(styleOption)
            customMapStyleEnabled = true
        }
        
        addAnnotations([searchCenterPin, userLocationPin])
        add(searchCircle)
    }
    
    // MARKER: Mapview Delegate
    lazy var zoomLevelRecord: CGFloat = zoomLevel
    func mapView(_ mapView: MAMapView!, mapWillZoomByUser wasUserAction: Bool) {
        if mode == .edit && wasUserAction {
            zoomLevelRecord = mapView.zoomLevel
        }
    }
    func mapViewRegionChanged(_ mapView: MAMapView!) {
        if mode == .edit {
            searchCircle.coordinate = mapView.centerCoordinate
            searchCenterPin.coordinate = mapView.centerCoordinate
            
            let deltaZoom = zoomLevelRecord - mapView.zoomLevel
            zoomLevelRecord = mapView.zoomLevel
            if mapView.zoomLevel <= MapViewController.maxSearchRadiusZoomLevel {
                searchCircle.radius = MapViewController.maxSearchRadius
            } else if mapView.zoomLevel >= MapViewController.minSearchRadiusZoomLevel {
                searchCircle.radius = MapViewController.minSearchRadius
            } else if abs(deltaZoom) > 0.01 {
                searchCircle.radius = searchCircle.radius * Double(pow(2.0, deltaZoom))
                print("scale circle")
            }
            print("zoomLevel: \(mapView.zoomLevel), radius: \(searchCircle.radius)")
        }
    }
    func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool) {
        if mode == .edit {
            searchCircle.coordinate = mapView.centerCoordinate
            searchCenterPin.coordinate = mapView.centerCoordinate
        }
        
        addAnnotations(toMapView: self)
        
        // ??
        selectAnnotation(searchCenterPin, animated: false)
    }
    
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        if let annotation = annotation as? ClusterAnnotation {
            let pointReuseIndetifier = "pointReuseIndetifier"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier) as? ClusterAnnotationView
            
            if annotationView == nil {
                annotationView = ClusterAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
            }
            
            annotationView?.annotation = annotation
            annotationView?.count = UInt(annotation.count)
            annotationView?.addShadowSubview(at: annotationView!.bounds.rightBottom.offset(dx: -5, dy: -8))
            
            return annotationView
        } else if let annotation = annotation as? CustomedAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.type.identifier) ?? MAAnnotationView(annotation: annotation, reuseIdentifier: annotation.type.identifier)
            view?.image = annotation.type.image
            view?.centerOffset = annotation.type.centerOffset
            annotation.view = view
            return view
        }
        return nil
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

    private var loadingIndicator = UIActivityIndicatorView()
    private var firstLoad = true {
        didSet {
            if firstLoad == false {
                loadingIndicator.stopAnimating()
                searchCenterPin.view?.isHidden = false
            }
        }
    }
    func mapViewWillStartLoadingMap(_ mapView: MAMapView!) {
        print("will start load map")
        // 确保 search center pin 在 user location pin 上面
        mapView.selectAnnotation(searchCenterPin, animated: false)
        if firstLoad {
            searchCenterPin.view?.imageView.center.y = -bounds.height / 2
            searchCenterPin.view?.isHidden = true
        }
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MAMapView!) {
        if firstLoad {
            firstLoad = !firstLoad
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.25,
                                                           delay: 0.0,
                                                           options: .curveEaseIn,
                                                           animations: {
                                                            self.searchCenterPin.view?.imageView.frame.origin.y = 0
            }, completion: { (_) in
                self.firstLoadCompletion?()
            })
        }
    }
    
    var coordinateQuadTree = CoordinateQuadTree()
    
    
    func synchronized(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    func updateMapViewAnnotations(annotations: [ClusterAnnotation]?) {
        /* 用户滑动时，保留仍然可用的标注，去除屏幕外标注，添加新增区域的标注 */
        let before = NSMutableSet(array: self.annotations)
        before.remove(searchCenterPin)
        before.remove(userLocationPin)
        let after: Set<NSObject> = annotations != nil ? NSSet(array: annotations!) as Set<NSObject> : Set<NSObject>()
        
        /* 保留仍然位于屏幕内的annotation. */
        var toKeep: Set<NSObject> = NSMutableSet(set: before) as Set<NSObject>
        toKeep = toKeep.intersection(after)
        
        /* 需要添加的annotation. */
        let toAdd = NSMutableSet(set: after)
        toAdd.minus(toKeep)
        
        /* 删除位于屏幕外的annotation. */
        let toRemove = NSMutableSet(set: before)
        toRemove.minus(after)
        
        DispatchQueue.main.async(execute: { [weak self] () -> Void in
            self?.addAnnotations(toAdd.allObjects)
            self?.removeAnnotations(toRemove.allObjects)
        })
    }
    
    
    var shouldRegionChangeReCalculate = false
    
    func addAnnotations(toMapView mapView: MAMapView) {
        synchronized(lock: self) { [weak self] in
            
            guard (self?.coordinateQuadTree.root != nil) || self?.shouldRegionChangeReCalculate != false else {
                print("tree is not ready.")
                return
            }
            
            guard let aMapView = self else {
                return
            }
            
            let visibleRect = aMapView.visibleMapRect
            let zoomScale = Double(aMapView.bounds.size.width) / visibleRect.size.width
            let zoomLevel = Double(aMapView.zoomLevel)
            
            DispatchQueue.global(qos: .default).async(execute: { [weak self] in
                
                let annotations = self?.coordinateQuadTree.clusteredAnnotations(within: visibleRect, withZoomScale: zoomScale, andZoomLevel: zoomLevel)
                
                self?.updateMapViewAnnotations(annotations: annotations as? [ClusterAnnotation])
            })
        }
    }
}

extension MapView {
    enum MapViewMode {
        case normal
        case edit
    }
}
