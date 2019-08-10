//
//  Restaurant.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/6.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import Foundation

struct Restaurant {
    var uid: String = ""
    var coordinate = kCLLocationCoordinate2DInvalid
    var title: String = ""
    var address: String = ""
    var tel = [String]()
    var images = [(title: String, url: URL?)]()
    var openTime: String?
    var rating: CGFloat = 0.0
    var avgCost: CGFloat = 0
    var type: String = ""
    
    
    init(with poi: AMapPOI) {
        if let latitude = poi.location?.latitude, let longitude = poi.location?.longitude {
            coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(latitude), CLLocationDegrees(longitude))
        }
        uid = poi.uid
        title = poi.name
        address = poi.address
        tel = poi.tel.split(separator: ";").map { String($0).trimmingCharacters(in: CharacterSet(charactersIn: " ")) }
        poi.images.forEach { images.append(($0.title, URL(string: $0.url)))}
        avgCost = poi.extensionInfo.cost
        openTime = poi.extensionInfo.openTime
        rating = poi.extensionInfo.rating
        type = poi.type
    }
    
    init() {}
}
