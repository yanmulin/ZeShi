//
//  LocationAnnotation.swift
//  ShiMie
//
//  Created by 颜木林 on 2019/7/30.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

class CustomedAnnotation: MAPointAnnotation {
    var type: annotationTyped
    weak var view: MAAnnotationView? {
        didSet {
            if type == .searchCenter, let view = view {
                view.addShadowSubview()
            }
        }
    }
    
     init(with type: annotationTyped) {
        self.type = type
        super.init()
    }
    
    override convenience init() {
        self.init(with: .restaurant)
    }
}

extension CustomedAnnotation {
    enum annotationTyped {
        case user
        case searchCenter
        case restaurant
        
        var identifier: String {
            switch self {
            case .user: return "UserLocationAnnotation"
            case .searchCenter: return "SearchCenterAnnotation"
            case .restaurant: return "RestaurantLocationAnnotation"
            }
        }
        
        var image: UIImage? {
            switch self {
            case .user: return UIImage(named: "userLocationAnnotation")
            case .searchCenter: return UIImage(named: "searchCenter-pin")
            case .restaurant: return UIImage(named: "restaurantLocationAnnotation")
//            default: return nil
            }
        }
        
        var centerOffset: CGPoint {
            switch self {
            case .searchCenter:
                return CGPoint(x: 0, y: -image!.size.height/2)
            default: return CGPoint(x: 0, y: 0)
            }
        }
    }
}
