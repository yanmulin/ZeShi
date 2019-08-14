//
//  POISearchManager.swift
//  ShiMie
//
//  Created by 颜木林 on 2019/8/6.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import Foundation

protocol POISearchManagerDelegate: NSObject {
    func onSearchDone(newPois: [AMapPOI], total: Int, first: Bool)
}

class POISearchManager:NSObject, AMapSearchDelegate {
    
    weak var delegate: POISearchManagerDelegate? {
        didSet { cancelAllRequests() }
    }
    
    var POISearchResultCount = 0
    
    func cancelAllRequests() {
        search?.cancelAllRequests()
    }
    
    func search(for uid: String) {
        let request = AMapPOIIDSearchRequest()
        request.uid = uid
        request.requireExtension = true
        search?.aMapPOIIDSearch(request)
    }
    
    func search(in coordinate: CLLocationCoordinate2D, with radius: CGFloat) {
        search?.cancelAllRequests()
        let request = AMapPOIAroundSearchRequest()
        request.types = "餐饮服务"
        request.location = AMapGeoPoint.location(withLatitude: CGFloat(coordinate.latitude), longitude: CGFloat(coordinate.longitude))
        request.radius = Int(radius)
        request.offset = 20
        request.requireExtension = true
        search(with: request, 1)
    }
    
    private func search(with request: AMapPOIAroundSearchRequest, _ page: Int) {
        request.page = page
        search?.aMapPOIAroundSearch(request)
    }
    
    private lazy var search = { () -> AMapSearchAPI? in
        let search = AMapSearchAPI()
        search?.delegate = self
        return search
    }()
    
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        POISearchResultCount = response.count
        if let request = request as? AMapPOIAroundSearchRequest {
            POISearchResultCount = response.count
            print("around search page#\(request.page) \(response.pois.count) done, total \(response.count) pois")
            if request.page == 1 {
                let maxPage = response.count / request.offset + (response.count % request.offset == 0 ? 0 : 1)
                if maxPage > 2 {
                    for p in 2...maxPage {
                        let request = request.copy() as! AMapPOIAroundSearchRequest
                        search(with: request, p)
                    }
                }
            }
            delegate?.onSearchDone(newPois: response.pois, total: response.count, first: request.page == 1)
        } else if let request = request as? AMapPOIIDSearchRequest {
            print("id search page#\(request.page) \(response.pois.count) done, total \(response.count) pois")
            delegate?.onSearchDone(newPois: response.pois, total: response.count, first: true)
        }
    }
    
    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        let err = error as NSError
        if err.code == 1806, let view = UIApplication.shared.keyWindow?.rootViewController?.view {
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            hud.mode = .text;
            hud.label.text = "网络连接不通畅"
            hud.label.numberOfLines = 0
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+1) { [weak view] in
                if let view = view {
                    MBProgressHUD.hide(for: view, animated: true)
                }
            }
        }
    }
}
