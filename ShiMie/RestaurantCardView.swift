//
//  CardView.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/6.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

class RestaurantCardView: UIView {
    
    var number: Int = 0 {
        didSet { label.text = "\(number)" }
    }
    var row: Int = 0
    
    var isAnimating = false
    private var _propertyAnimator: UIViewPropertyAnimator?
    var propertyAnimator: UIViewPropertyAnimator?
    
    lazy var label = makeLabel()
    
    func makeLabel() -> UILabel {
        let label = UILabel()
        addSubview(label)
        return label
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: 15, y: 5, width: 50, height: 50)
        label.font = UIFont.preferredFont(forTextStyle: .title1)
    }
    
    var zDistance: CGFloat = 0.0 {
        didSet {
            if isRolling {
                tilt(to: -CGFloat.pi / 6, animated: false)
            }
        }
    }
    var isRolling = false {
        didSet {
            if oldValue != isRolling {
                if isRolling {
                    tilt(to: -CGFloat.pi / 6, animated: false)
                } else {
                    layer.transform = CATransform3DIdentity
                }
            }
        }
    }
    
    private var rotation: CGFloat = CGFloat.zero
    
    func tilt(to degree: CGFloat, animated: Bool) {
        var t = CATransform3DIdentity
        layer.removeAnimation(forKey: "tilt-animation")
        // m34 控制深度？
        if degree != CGFloat.zero {
            t.m34 = -zDistance
            t = CATransform3DRotate(t, degree, 1, 0, 0)
        }
        if animated {
            let animation = CABasicAnimation(keyPath: "transform.rotation.x")
            print("\(layer.transform)")
            animation.fromValue = rotation
            animation.toValue = degree
//            animation.duration = 3.0
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            layer.add(animation, forKey: "tilt-animation")
        } else {
            layer.transform = t
        }
        rotation = degree
    }
}
