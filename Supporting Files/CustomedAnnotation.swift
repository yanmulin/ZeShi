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
                view.addShadowSubview(at: CGPoint(x: 8, y: type.image!.size.height))
            }
        }
    }
    
     init(with type: annotationTyped) {
        self.type = type
        super.init()
    }
    
    override convenience init() {
        self.init(with: .restaurant(genre: 0))
    }
}

extension CustomedAnnotation {
    enum annotationTyped: Equatable {
        case user
        case searchCenter
        case restaurant(genre: Int)
        
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
            case .searchCenter: return UIImage(named: "fork")
            case .restaurant: return UIImage(named: "restaraunt-icon")
//            default: return nil
            }
        }
        
        var centerOffset: CGPoint {
            switch self {
            case .searchCenter:
//                return CGPoint(x: image!.size.width/2-1, y: -image!.size.height/2)
                return CGPoint(x: 0, y: -image!.size.height/2)
            default: return CGPoint(x: 0, y: 0)
            }
        }
    }
}
