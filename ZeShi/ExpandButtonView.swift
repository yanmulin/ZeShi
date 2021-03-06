//
//  ExpandButtonView.swift
//  ShiMie
//
//  Created by 颜木林 on 2019/7/15.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

@IBDesignable
class ExpandButtonView: UIView {
    
    @IBInspectable var expand = false {
        didSet {
            if expand {
                slider?.isHidden = false
            }
            slider?.isEnabled = expand
            setNeedsLayout()
        }
    }
    
    var slider: UISlider? {
        didSet {
            if let slider = slider {
                slider.isHidden = !expand
                slider.frame = CGRect(x: 0, y: 0, width: sliderHeight, height: sliderWidth)
                slider.transform = CGAffineTransform.identity
                    .translatedBy(x: -sliderHeight/2 + sliderWidth/2, y: sliderHeight/2 - sliderWidth/3)
                    .rotated(by: CGFloat.pi / 2)
                sliderBoxView.addSubview(slider)
            }
        }
    }
    
    var upperButton: UIButton? {
        didSet {
            if let oldValue = oldValue {
                oldValue.removeFromSuperview()
            }
            if let newButton = self.upperButton {
                newButton.frame.size = upperButtonBoxRect.size
                upperButtonBoxView.addSubview(newButton)
//                newButton.backgroundColor = #colorLiteral(red: 0.9725490196, green: 0.2156862745, blue: 0.04705882353, alpha: 1)
                newButton.center = upperButtonBoxView.bounds.center
            }
        }
    }
    
    var lowerButton: UIButton? {
        didSet {
            if let oldValue = oldValue {
                oldValue.removeFromSuperview()
            }
            if let newButton = self.lowerButton {
                newButton.frame.size = lowerButtonBoxRect.size
                lowerButtonBoxView.addSubview(newButton)
//                newButton.backgroundColor = #colorLiteral(red: 0.9725490196, green: 0.2156862745, blue: 0.04705882353, alpha: 1)
                newButton.center = lowerButtonBoxView.bounds.center
            }
        }
    }
    
    private lazy var upperButtonBoxView = makeButtonBoxView(in: upperButtonBoxRect, upsideDown: false)
    private lazy var lowerButtonBoxView = makeButtonBoxView(in: lowerButtonBoxRect, upsideDown: true)
    private lazy var sliderBoxView = makeSliderBoxView()
    
    func makeButtonBoxView(in rect: CGRect, upsideDown: Bool) -> UIView {
        let view = UIView(frame: rect)
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = makeButtonBoxPath(in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height), inverse: upsideDown).cgPath
        shapeLayer.fillColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        shapeLayer.strokeColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        shapeLayer.lineWidth = mediumLineWidth
        view.layer.addSublayer(shapeLayer)
        addSubview(view)
//        view.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
        return view
    }
    
    private func makeButtonBoxPath(in rect: CGRect, inverse: Bool) -> UIBezierPath {
        let path = UIBezierPath.init()
        let radius = min(rect.height, rect.width) / 2
        let startX = rect.width / 2 - radius
        path.move(to: bounds.origin.offset(dx: startX, dy: rect.maxY))
        path.addLine(to: bounds.origin.offset(dx: startX, dy: radius))
        path.addArc(withCenter: bounds.origin.offset(dx: radius, dy: radius) , radius: radius, startAngle: CGFloat.pi, endAngle: CGFloat.pi * 2, clockwise: true)
        path.addLine(to: bounds.origin.offset(dx: rect.maxX - startX, dy: rect.maxY))
        path.addLine(to: bounds.origin.offset(dx: startX, dy: rect.maxY))
        path.close()
        if inverse {
            path.apply(CGAffineTransform.init(translationX: rect.maxX, y: rect.maxY).rotated(by: CGFloat.pi))
        }
//        path.apply(CGAffineTransform.init(translationX: rect.minX + startX, y: rect.minY))
        return path
    }
    
    func makeSliderBoxView() -> UIView {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        view.layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        view.layer.borderWidth = mediumLineWidth
        view.clipsToBounds = true
        addSubview(view)
        return view
    }
    
    // MARKER: Layout functions
    private func configureUpperButtonBoxView(of view: UIView) {
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: ExpandButtonView.defaultAnimationDuration,
            delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                view.frame = self.upperButtonBoxRect
        }, completion: nil)
    }
    
    private func configureLowerButtonBoxView(of view: UIView) {
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: ExpandButtonView.defaultAnimationDuration,
            delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                view.frame = self.lowerButtonBoxRect
        }, completion: nil)
    }
    
    private func configureSliderBoxView(of view: UIView) {
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: ExpandButtonView.defaultAnimationDuration,
            delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                view.frame = self.sliderBoxRect
        }, completion: { (_) in
            if !self.expand {
                self.slider?.isHidden = true
            }
        })}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        configureUpperButtonBoxView(of: upperButtonBoxView)
        configureLowerButtonBoxView(of: lowerButtonBoxView)
        configureSliderBoxView(of: sliderBoxView)
    }

}

extension ExpandButtonView {
    var buttonHeight: CGFloat {
        return bounds.height * 0.2 - mediumLineWidth
    }

    
    var mediumLineWidth: CGFloat {
        return 1
    }
    
    var upperButtonBoxRect: CGRect {
        return CGRect(x: 0, y: 0, width: bounds.width, height: buttonHeight)
    }
    
    var lowerButtonBoxRect: CGRect {
        return CGRect(x: 0, y: buttonHeight + sliderBoxHeight, width: bounds.width, height: buttonHeight)
    }
    
    var sliderBoxRect: CGRect {
        return CGRect(x: (bounds.width - sliderWidth) / 2, y: upperButtonBoxRect.maxY, width: sliderWidth, height: sliderBoxHeight)
    }
    
    var sliderBoxHeight: CGFloat {
        return expand ? sliderHeight + 0.05 * bounds.height : 5
    }
    
    var sliderWidth: CGFloat {
        return min(upperButtonBoxRect.width, upperButtonBoxRect.height) * 0.9
    }
    
    var sliderHeight: CGFloat {
        return bounds.height * 0.5
    }
    
    static let defaultAnimationDuration: TimeInterval = 0.2
}
