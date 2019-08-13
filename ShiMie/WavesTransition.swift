//
//  WaveTransition.swift
//  ShiMie
//
//  Created by 颜木林 on 2019/8/8.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

class WavesTransition: NSObject {
    var duration = 6.0
    var carryInView = UIView()
    var carryViewOriginalCenter = CGPoint.zero
    private var wavesView = UIView()
    private lazy var waveLayer1 = makeShapeLayer(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
    private lazy var waveLayer2 = makeShapeLayer(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
    private lazy var waveLayer3 = makeShapeLayer(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1))
    private lazy var antiWaveView = UIView()
    private lazy var antiWaveLayer = makeShapeLayer(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1))
    private var emojiChoices = "🦐🐠🐡🦑🦀🐙🐟🐬🐳🐋🦈"
    private lazy var emojiViews = [UIView]()
    
    private func makeShapeLayer(_ fillColor: CGColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        layer.fillColor = fillColor
        layer.strokeColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        layer.lineWidth = 3.0
        layer.frame = wavesView.bounds
        return layer
    }
    
    
    private var displayLink: CADisplayLink?
    private var halfway: (()->Void)?
    private var completion: (()->Void)?
    
    private func startAnimation() {
        t = 0
        random = 10.arc4random * 20
        wavesView.layer.addSublayer(waveLayer1)
        wavesView.layer.addSublayer(waveLayer2)
        wavesView.layer.addSublayer(waveLayer3)
        antiWaveView.layer.addSublayer(antiWaveLayer)
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(tick(_:)))
        displayLink?.add(to: .current, forMode: .default)
    }
    
    private var t = 0
    private var random = 1000.arc4random
    @objc func tick(_ displayLink: CADisplayLink) {
        let firstDistance = waveMoveDistance(at: t, 0)
        let secondDistance = waveMoveDistance(at: t, 1)
        let thirdDistance = waveMoveDistance(at: t, 2)
        updateWave(waveLayer1, at: t, firstDistance)
        updateWave(waveLayer2, at: t-25, secondDistance)
        updateWave(waveLayer3, at: t-50, thirdDistance)
        updateWave(antiWaveLayer, at: t, firstDistance, true)
        emojiViews.forEach { $0.isHidden = false; $0.transform = CGAffineTransform(translationX: 0, y: thirdDistance) }
        t += 1
        
//        if halfway == nil {
//            if firstDistance > carryViewOriginalCenter.y {
//                carryInView.center = carryViewOriginalCenter
//            } else {
//                carryInView.center = CGPoint(x: carryViewOriginalCenter.x, y: firstDistance)
//            }
//        }
        
        if secondDistance < 0 {
            halfway?()
            halfway = nil
        } else if secondDistance > wavesView.bounds.height {
            completion?()
            completion = nil
            displayLink.invalidate()
        }
    }
    
    private func wave(x: CGFloat) -> CGFloat {
        let stdFreq = 2 * CGFloat.pi / wavesView.bounds.width
        return 20 * ((3 * sin(1.3 * stdFreq * x) + 5 * sin(0.7 * stdFreq * x) + sin(0.3 * stdFreq * x)) / 7 + 0.5)
    }
    
    func updateWave(_ layer: CAShapeLayer, at t: Int, _ y_offset: CGFloat, _ upsideDown: Bool = false) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: y_offset))
        for x in stride(from: 0, through: wavesView.bounds.width, by: 1) {
            path.addLine(to: CGPoint(x: x, y: wave(x: x - 5 * CGFloat(t) - CGFloat(random)) + y_offset))
        }
        if upsideDown == false {
            path.addLine(to: wavesView.bounds.rightBottom)
            path.addLine(to: wavesView.bounds.leftBottom)
        } else {
            path.addLine(to: wavesView.bounds.rightTop)
            path.addLine(to: wavesView.bounds.leftTop)
        }
        path.closeSubpath()
        layer.path = path
    }
    
    // 临界阻尼
    private func waveMoveDistance(at t: Int, _ order: CGFloat) -> CGFloat {
        let stdFreq = 2 * CGFloat.pi / wavesView.bounds.width
        let t = t > 2 * 60 ? 4 * 60 - t : t
        let descentFactor = exp(-0.7 * stdFreq * CGFloat(t))
        let descentLine = (wavesView.bounds.height - wavesView.bounds.height / 2 / 60 * CGFloat(t))
        return descentFactor * (descentLine - 4 * (2 - order) * (CGFloat(t) + 10))
    }
}

extension WavesTransition: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView
        let fromViewController = transitionContext.viewController(forKey: .from)
        let toViewController = transitionContext.viewController(forKey: .to)
        let presentedControllerView = transitionContext.view(forKey: .to)!
        presentedControllerView.isHidden = true
        containerView.addSubview(presentedControllerView)
        
        
        wavesView = UIView()
        wavesView.frame = presentedControllerView.frame
        containerView.addSubview(wavesView)
        
        fromViewController?.beginAppearanceTransition(false, animated: true)
        if toViewController?.modalPresentationStyle == .custom {
            toViewController?.beginAppearanceTransition(true, animated: true)
        }
        
//        carryInView.center = CGPoint(x: carryViewOriginalCenter.x, y: -carryInView.bounds.height / 2)
        carryInView.center = carryViewOriginalCenter
        carryInView.mask = antiWaveView
        carryInView.isHidden = true
        containerView.addSubview(carryInView)
        
        halfway = {
            presentedControllerView.isHidden = false
            self.carryInView.isHidden = false
            self.carryInView.center.y = self.carryInView.bounds.height
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 1.5, options: .curveEaseInOut, animations: {
                self.carryInView.center.y = self.carryViewOriginalCenter.y
            })
        }
        
        completion = { [weak self] in
            self?.wavesView.removeFromSuperview()
            if let carryInView = self?.carryInView, let originalCenter = self?.carryViewOriginalCenter {
                carryInView.removeFromSuperview()
                toViewController?.view.addSubview(carryInView)
                carryInView.center = originalCenter
            }
            transitionContext.completeTransition(true)
            if toViewController?.modalPresentationStyle == .custom {
                toViewController?.endAppearanceTransition()
            }
            fromViewController?.endAppearanceTransition()
            self?.emojiViews.forEach { $0.removeFromSuperview() }
            self?.emojiViews.removeAll()
        }
        
        func makeEmojiLabel(_ emoji: String, at origin: CGPoint) -> UILabel {
            let label = UILabel()
            label.text = emoji
            label.font = UIFont.systemFont(ofSize: 48)
            label.sizeToFit()
            label.frame.origin = origin
            containerView.addSubview(label)
            return label
        }
        let xrange = ClosedRange(uncheckedBounds: (40, containerView.bounds.width - 40))
        let yrange = ClosedRange(uncheckedBounds: (150, containerView.bounds.height - 20))
        var emojis = emojiChoices
        for _ in 0..<5 + 5.arc4random {
            let emojiIndex = emojis.index(emojiChoices.startIndex, offsetBy: emojis.count.arc4random)
            let emoji = emojis.remove(at: emojiIndex)
            let label = makeEmojiLabel(_: String(emoji), at: CGPoint(x: CGFloat.random(in: xrange), y: CGFloat.random(in: yrange)))
            label.isHidden = true
            emojiViews.append(label)
        }
        
        startAnimation()
    }
}
