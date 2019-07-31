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
    
    var rightBottom: CGPoint {
        return self.origin.offset(dx: self.width, dy: self.height)
    }
}

extension UIView {
    static let shadowViewTag = 112233
    var shadowSubview: UIView? {
        return subviews.first(where: { $0.tag == UIView.shadowViewTag }) ?? nil
    }
    func addShadowSubview() {
        if let shadowView = shadowSubview {
            shadowView.removeFromSuperview()
        }
        if let image = UIImage(named: "shadow") {
            let shadowView = UIImageView(image: image)
            shadowView.tag = UIView.shadowViewTag
            addSubview(shadowView)
            shadowView.sizeToFit()
            shadowView.center = CGPoint(x: bounds.width / 2, y: bounds.height)
            clipsToBounds = false
        }
    }
}
