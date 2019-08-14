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
// ✅ TODO: 添加进入Edit mode 动画
// ✅ TODO: MapView 类
// ✅ TODO: locate按钮 search center pin无法移动到user location pin上
// ✅ TODO: 修改 进入edit mode 根据 search circle radius 改变zoom level
// ✅ TODO: BUG 移动search circle并将半径设为最小 退出编辑模式 缩放zoomLevel到最小 点击定位 点击编辑 半径错误


class MapViewController: UIViewController, AMapSearchDelegate, UIViewControllerTransitioningDelegate, POISearchManagerDelegate {
    
    private func setupTitle(update: Bool = true) {
        if mapView.mode == .edit {
            title = "编辑模式"
        }else if update == true && restarauts.count == 0 {
            title = "地图页"
            poiSearchManager.search(in: mapView.searchCenterPin.coordinate, with: CGFloat(mapView.searchCircle.radius))
        } else {
            title = "附近搜到\(restarauts.count)家餐厅"
        }
    }
    
    var restarauts = [Restaurant]()
    
    private var transition = WavesTransition()
    private var poiSearchManager = POISearchManager()
    
    @IBAction func trigger(_ sender: Any) {
        if restarauts.count == 0 {
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            hud.mode = .text;
            hud.label.text = "暂无餐厅\n请先进入编辑模式搜索"
            hud.label.numberOfLines = 0
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+1) { [weak self] in
                if let view = self?.view {
                    MBProgressHUD.hide(for: view, animated: true)
                }
            }
        }else  {
            performSegue(withIdentifier: "showDetail", sender: sender)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? RestaurantDetailViewController {
            vc.transitioningDelegate = self
            vc.restaraut = restarauts.randomElement()!
            vc.modalPresentationStyle = .custom
        } else if let vc = segue.destination as? CardListViewController {
            DispatchQueue.main.async {
                vc.restaurants = self.restarauts
                vc.cardListView.setNeedsReload()
            }
        }
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let presented = presented as? RestaurantDetailViewController {
            let imageView = UIImageView(image: UIImage(named: "restaraunt-icon"))
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 200, height: 200))
            transition.carryInView = imageView
            transition.carryViewOriginalCenter = presented.view.center
        }
        return transition
    }
    
    @IBOutlet weak var mapView: MapView!
    
    @IBOutlet weak var triggerButton: UIButton! {
        didSet {
            triggerButton.layer.cornerRadius = triggerButton.bounds.width / 2
            triggerButton.layer.shadowColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            triggerButton.layer.shadowOffset = CGSize(width: 1, height: 1)
            triggerButton.layer.shadowRadius = 2.0
        }
    }
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBOutlet weak var expandButtonView: ExpandButtonView! {
        didSet {
            expandButtonView.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            expandButtonView.layer.shadowRadius = 2.0
            expandButtonView.layer.shadowOffset = CGSize(width: 1, height: 1)
            expandButtonView.layer.shadowOpacity = 0.6
        }
    }
    private var slider = UISlider()
    
    private lazy var locateButton = makeButton(UIImage(named: "locate"), #selector(locate(_:)))
    
    private lazy var editButton = makeButton(UIImage(named: "pencil"), #selector(edit(_:)))
    
    private func makeButton(_ image: UIImage?, _ selector: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }
    
    @IBOutlet weak var editModeBannerView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSlider(slider)
        expandButtonView.upperButton = locateButton
        expandButtonView.lowerButton = editButton
        setupEditModeButton(confirmButton)
        setupEditModeButton(cancelButton)
        poiSearchManager.delegate = self
        view.isUserInteractionEnabled = false
        
        LocationManager.shared.locate (at: kCLLocationAccuracyNearestTenMeters) { [weak self] (location) in
            self?.mapView.userLocationPin.coordinate = location.coordinate
            self?.mapView.setCenter(location.coordinate, animated: true)
            self?.mapView.searchCircle.coordinate = location.coordinate
            self?.mapView.searchCenterPin.coordinate = location.coordinate
        }
        
        mapView.firstLoadCompletion = { [weak self] in
            self?.poiSearchManager.search(in: self!.mapView.searchCenterPin.coordinate, with: CGFloat(self!.mapView.searchCircle.radius))
            self?.view.isUserInteractionEnabled = true
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupTitle()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        poiSearchManager.cancelAllRequests()
        title = "地图页"
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private var lastSearchCenterCoordinate = kCLLocationCoordinate2DInvalid
    private var lastSearchRadius: Double = 0
    @IBAction func cancelEditMode(_ sender: Any) {
        mapView.mode = .normal
        expandButtonView.expand = !expandButtonView.expand
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3,
                                                       delay: 0.0,
                                                       options: .curveEaseInOut,
                                                       animations: {
                                                        self.editModeBannerView.center.y += 100
                                                        self.triggerButton.center.y -= 250
        }) { (_) in
            self.editModeBannerView.isHidden = !self.editModeBannerView.isHidden
            self.setupTitle()
        }
        editButton.isEnabled = true
        mapView.searchCenterPin.coordinate = lastSearchCenterCoordinate
        mapView.searchCircle.radius = lastSearchRadius
        mapView.searchCircle.coordinate = lastSearchCenterCoordinate
        mapView.setCenter(lastSearchCenterCoordinate, animated: true)
        mapView.addAnnotations(toMapView: mapView)
    }
    @IBAction func confirmEditMode(_ sender: Any) {
        poiSearchManager.search(in: mapView.searchCenterPin.coordinate, with: CGFloat(mapView.searchCircle.radius))
        expandButtonView.expand = !expandButtonView.expand
        mapView.coordinateQuadTree.clean()
        mapView.updateMapViewAnnotations(annotations: nil)
        restarauts.removeAll()
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3,
                                                       delay: 0.0,
                                                       options: .curveEaseInOut,
                                                       animations: {
                                                        self.editModeBannerView.center.y += 100
                                                        self.triggerButton.center.y -= 250
        }) { (_) in
            self.setupTitle()
            self.editModeBannerView.isHidden = !self.editModeBannerView.isHidden
            self.mapView.searchCenterPin.coordinate = self.mapView.centerCoordinate
            
        }
        editButton.isEnabled = true
        self.mapView.mode = .normal
    }
    
    
    private func setupEditModeButton(_ button: UIButton) {
        button.layer.cornerRadius = button.bounds.height / 2
        button.layer.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        button.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        button.layer.shadowOpacity = 0.25
        button.layer.shadowOffset = CGSize(width: 1, height: 1)
        button.layer.shadowRadius = 0.25
    }
    
    private func setupSlider(_ slider: UISlider) {
        slider.thumbTintColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        slider.minimumTrackTintColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        slider.minimumValue = Float(MapViewController.minZoomLevel)
        slider.maximumValue = Float(MapViewController.maxZoomLevel)
        slider.value = Float(MapViewController.defaultZoomLevel)
        expandButtonView.slider = slider
        slider.addTarget(self, action: #selector(sliderValueChange(_:)), for: .valueChanged)
    }
    
    @objc private func sliderValueChange(_ sender: Any) {
        if let slider = sender as? UISlider {
            if abs(mapView.zoomLevel - CGFloat(slider.value)) > 0.01 {
//                mapView.zoomLevelRecord = mapView.zoomLevel
                mapView.setZoomLevel(CGFloat(slider.value), animated: true)
            }
        }
    }
    @objc private func locate(_ sender: Any) {
        print("click locate button")
        if mapView.mode == .edit {
            if let location = LocationManager.shared.lastLocation {
                // 这里不需要设置searchCircle.coordinate和searchCenterPin.coordinate,因为在edit mode下mapView.setCenter会使它们跟随屏幕移动
                mapView.userLocationPin.coordinate = location
//                searchCircle.coordinate = location.coordinate
//                searchCenterPin.coordinate = location.coordinate
                mapView.setCenter(location , animated: true)
            }
            LocationManager.shared.locate (at: kCLLocationAccuracyNearestTenMeters) { [weak self] (location) in
                self?.mapView.userLocationPin.coordinate = location.coordinate
                if self?.mapView.mode == .edit {
                    self?.mapView.searchCircle.coordinate = location.coordinate
                    self?.mapView.searchCenterPin.coordinate = location.coordinate
                }
            }
        } else {
            if let location = LocationManager.shared.lastLocation {
                mapView.setCenter(location, animated: false)
            }
            LocationManager.shared.locate (at: kCLLocationAccuracyNearestTenMeters) { [weak self] (location) in
                self?.mapView.userLocationPin.coordinate = location.coordinate
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
        poiSearchManager.cancelAllRequests()
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3,
                                                       delay: 0.0,
                                                       options: .curveEaseInOut,
                                                       animations: {
                                                        self.editModeBannerView.center.y -= 100
                                                        self.triggerButton.center.y += 250
        },completion: { (_) in
            self.setupTitle()
        })
        editButton.isEnabled = false
        mapView.updateMapViewAnnotations(annotations: nil)
        lastSearchCenterCoordinate = mapView.searchCenterPin.coordinate
        lastSearchRadius = mapView.searchCircle.radius
        self.mapView.mode = .edit
        editModeBannerView.isHidden = !editModeBannerView.isHidden
        expandButtonView.expand = !expandButtonView.expand
    }

    func onSearchDone(newPois: [AMapPOI], total: Int, first: Bool) {
        if first {
            mapView.coordinateQuadTree = CoordinateQuadTree(BoundingBox(with: mapView.searchCircle.boundingMapRect), maxCount: Int32(total/20 + (total%20==0 ? 0 : 1)) * 20)
        }
        
        restarauts.append(contentsOf: newPois.map { Restaurant(with: $0) })
        setupTitle(update: false)
        
        synchronized(lock: self) { [weak self] in
            self?.mapView.shouldRegionChangeReCalculate = false
            newPois.forEach { mapView.coordinateQuadTree.insert($0) }
            DispatchQueue.global(qos: .default).async(execute: { [weak self] in
                self?.mapView.shouldRegionChangeReCalculate = true
                DispatchQueue.main.async(execute: {
                    self?.mapView.addAnnotations(toMapView: (self?.mapView)!)
                })
            })
        }
        
    }
    
    func synchronized(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    
}

extension MapViewController {
    static let searchCircleFillColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.4)
    static let searchCircleStrokeColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).withAlphaComponent(0.6)
    static let searchCircleStrokeLineWidth: CGFloat = 2.0
    static let maxSearchRadius: CLLocationDistance = 2000
    static let minSearchRadius: CLLocationDistance = 200
    static let defaultSearchRadius: CLLocationDistance = 500
    
    static let defaultZoomLevel: CGFloat = 15.0
    static let minZoomLevel: CGFloat = 13.5
    static let maxZoomLevel: CGFloat = 17.2
    
    static let maxSearchRadiusZoomLevel: CGFloat = 13.7
    static let minSearchRadiusZoomLevel: CGFloat = 17.0
    
    static let defualtScreenCircleRatio:CGFloat = 0.8
}

