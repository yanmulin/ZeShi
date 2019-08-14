//
//  Utils.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/13.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

extension CGPoint {
    func offset(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
    
    static func ==(_ lhs: CGPoint, _ rhs: CGPoint) -> Bool {
        return lhs.x - rhs.x < 1e-6 && lhs.y - rhs.y < 1e-6
    }
}

extension CGSize {
    func offset(dw: CGFloat, dh: CGFloat) -> CGSize {
        return CGSize(width: self.width+dw, height: self.height+dh)
    }
}

extension CGRect {
    var center: CGPoint {
        return self.origin.offset(dx: self.width / 2, dy: self.height / 2)
    }
    
    var leftBottom: CGPoint {
        return self.origin.offset(dx: 0, dy: self.height)
    }
    
    var leftTop: CGPoint {
        return self.origin
    }
    
    var rightBottom: CGPoint {
        return self.origin.offset(dx: self.width, dy: self.height)
    }
    
    var rightTop: CGPoint {
        return self.origin.offset(dx: width, dy: 0)
    }
    
    func scale(by factor: CGFloat) -> CGRect {
        let newWidth = width * factor
        let newHeight = height * factor
        return CGRect(x: minX + (width - newWidth) / 2, y: minY + (height - newHeight) / 2, width: newWidth, height: newHeight)
    }
}

extension UIView {
    static let shadowViewTag = 112233
    var shadowSubview: UIView? {
        return subviews.first(where: { $0.tag == UIView.shadowViewTag }) ?? nil
    }
    func addShadowSubview(at center: CGPoint) {
        if let shadowView = shadowSubview {
            shadowView.removeFromSuperview()
        }
        if let image = UIImage(named: "shadow") {
            let shadowView = UIImageView(image: image)
            shadowView.tag = UIView.shadowViewTag
            insertSubview(shadowView, at: 0)
            shadowView.sizeToFit()
            shadowView.frame = shadowView.frame.scale(by: bounds.width / shadowView.bounds.width)
            shadowView.center = center
            clipsToBounds = false
        }
    }
}

extension Int {
    var arc4random: Int {
        return Int(arc4random_uniform(UInt32(self)))
    }
}

extension CLLocationCoordinate2D {
    init(with point: AMapGeoPoint?) {
        if let latitude = point?.latitude, let longitude = point?.longitude {
            self.init()
            self.latitude = CLLocationDegrees(latitude)
            self.longitude = CLLocationDegrees(longitude)
        } else {
            self = kCLLocationCoordinate2DInvalid
        }
    }
}

extension BoundingBox {
    init(with mapRect: MAMapRect) {
        let region = MACoordinateRegionForMapRect(mapRect)
        self = BoundingBoxMake(
            region.center.latitude - region.span.latitudeDelta / 2,
            region.center.longitude - region.span.longitudeDelta / 2,
            region.center.latitude + region.span.latitudeDelta / 2,
            region.center.longitude + region.span.longitudeDelta / 2
        )
    }
}

extension UIViewController {
    var contentVC: UIViewController? {
        if let nvc = self as? UINavigationController {
            return nvc.topViewController ?? nil
        } else {
            return self
        }
    }
}
