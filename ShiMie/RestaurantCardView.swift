//
//  CardView.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/6.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

@IBDesignable
class RestaurantCardView: UIView {
    
    var title: String = "" {
        didSet { setNeedsLayout() }
    }
    var address: String = "" {
        didSet { setNeedsLayout() }
    }
    var tel = [String]() {
        didSet { setNeedsLayout() }
    }
    var images = [(title: String, url: URL?)]() {
        didSet { setupImages(images); setNeedsLayout() }
    }
    var rating: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }
    var avgCost: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }
    var openTime: String = "" {
        didSet { setNeedsLayout() }
    }
    var type: String = "" {
        didSet { setNeedsLayout() }
    }
    
    private lazy var titleLab = makeLabel()
    private lazy var addressLab = makeLabel()
    private lazy var telLab = makeLabel()
    private lazy var imageViewsContainer: UIScrollView = { () -> UIScrollView in
        let scrollView = UIScrollView()
        addSubview(scrollView)
        scrollView.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        return scrollView
    }()
    private lazy var ratingLab = makeLabel()
    private lazy var avgCostLab = makeLabel()
    private lazy var openTimeLab = makeLabel()
    private lazy var typeLab = makeLabel()
    
    private lazy var ratingMaskLayer: CAShapeLayer = { () -> CAShapeLayer in
        let layer = CAShapeLayer()
        layer.fillColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        self.layer.addSublayer(layer)
        
        layer.mask = ratingStarsView.layer
        layer.frame = bounds
        layer.path = UIBezierPath(rect: bounds).cgPath
        return layer
    }()
    private lazy var ratingStarsView = makeStarsView()
    private lazy var ratingStarsBgView = makeStarsView()
    
    private func makeStarsView() -> UIView {
        let view = UIView()
        var rect = CGRect.zero
        for _ in 0..<5 {
            let imageView = UIImageView(image: UIImage(named: "star"))
            imageView.sizeToFit()
            imageView.frame.origin = rect.rightTop
            rect.size.width += imageView.frame.width
            rect.size.height = imageView.frame.height
            view.addSubview(imageView)
        }
        view.frame.size = rect.size
        addSubview(view)
        return view
    }
    
    private lazy var loadingIndicator = { () -> UIActivityIndicatorView in
        let indicator = UIActivityIndicatorView()
        addSubview(indicator)
        indicator.frame = CGRect(x: bounds.center.x - 15, y: bounds.center.y - 15, width: 30, height: 30)
        indicator.isHidden = true
        indicator.stopAnimating()
        return indicator
    }()
    
    var loading: Bool {
        set {
            if newValue {
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
            }
            loadingIndicator.isHidden = !newValue;
        }
        get { return loadingIndicator.isAnimating }
    }
    
    func setupCard(with restaraut: Restaurant) {
        title = restaraut.title
        address = restaraut.address
        tel = restaraut.tel
        images = restaraut.images
        rating = restaraut.rating
        avgCost = restaraut.avgCost
        openTime = restaraut.openTime ?? ""
        type = restaraut.type
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        self.contentMode = .redraw
        self.isOpaque = false
        self.clipsToBounds = false
    }
    
    private func setupImages(_ images: [(String, URL?)]) {
        
    }
    
    override func draw(_ rect: CGRect) {
        let outline = UIBezierPath(roundedRect: CGRect(origin: cardUpperLeft, size: cardSize), cornerRadius: cornerRadius)
        #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).setFill()
        #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).setStroke()
        outline.lineJoinStyle = .round
        outline.lineWidth = borderLineWidth
        outline.stroke()
        outline.fill()
        let tagPath = UIBezierPath()
        tagPath.move(to: tagUpperLeft)
        tagPath.addLine(to: tagLowerRight.offset(dx: 0, dy: -tagSize.height + 5))
        tagPath.addLine(to: tagLowerRight.offset(dx: 0, dy: -5))
        tagPath.addLine(to: tagUpperLeft.offset(dx: 0, dy: tagSize.height))
        tagPath.close()
        tagPath.lineJoinStyle = .round
        tagPath.lineWidth = 4.0
        #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1).setFill()
        tagPath.stroke()
        tagPath.fill()
        super.draw(rect)
    }
    
    var row: Int = 0
    
    var isAnimating = false
    private var _propertyAnimator: UIViewPropertyAnimator?
    var propertyAnimator: UIViewPropertyAnimator?
    
    private func makeLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        addSubview(label)
        return label
    }
    
    private func makeImagesContainer() -> UIScrollView {
        let scrollView = UIScrollView()
        addSubview(scrollView)
        return scrollView
    }
    
    private func configureLabel(_ label: UILabel, with attributedText: NSAttributedString) {
        label.attributedText = attributedText
        label.frame.size = label.sizeThatFits(labelRect.size)
    }
    
    private func configureRating(_ rating: CGFloat, with view: UIView, _ label: UILabel) {
        view.frame.origin = ratingOrigin
//        ratingMaskLayer.frame.origin = ratingOrigin
        ratingMaskLayer.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: ratingOrigin.x + view.frame.width * rating / 5.0, height: bounds.height)).cgPath
        configureLabel(label, with: makeBodyAttributedText(for: rating == 0 ? "未知" : "\(rating)", lightBodyFont))
        ratingLab.frame.origin = CGPoint(x: view.frame.maxX + smallLabelGap, y: view.frame.center.y - ratingLab.frame.height / 2)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        print("titleLab:\(title)")
        
        configureLabel(titleLab, with: rightAlignedTitleAttributedText(for: title))
        titleLab.frame.origin = labelRect.rightTop.offset(dx: -titleLab.frame.width, dy: 0)
        
        configureLabel(avgCostLab, with: makeBodyAttributedText(for: avgCost == 0 ? "人均 未知" : "人均 ¥\(avgCost)", lightBodyFont))
        avgCostLab.frame.origin = avgCostLabOrigin
        
        ratingStarsBgView.frame.origin = ratingOrigin
        configureRating(rating, with: ratingStarsView, ratingLab)
        
        configureLabel(addressLab, with: makeBodyAttributedText(for: address, lightBodyFont))
        addressLab.frame.origin = addressLabOrigin
        addressLab.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        
        configureLabel(telLab, with: makeBodyAttributedText(for: tel.joined(separator: " "), lightBodyFont))
        telLab.frame.origin = telLabOrigin
        telLab.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)

        imageViewsContainer.frame = imageContainerRect
        
        if openTime.count > 0 {
            configureLabel(openTimeLab, with: makeBodyAttributedText(for: openTime + " 营业", lightBodyFont))
            openTimeLab.frame.origin = openTimeLabOrigin
            openTimeLab.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        self.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        self.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.layer.shadowOpacity = 0.6
        self.layer.shadowRadius = 3
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

extension RestaurantCardView {
    private struct SizeRatio {
        static let cornerRadius2BoundsWidth: CGFloat = 0.05
        static let titleOffset2CornerRadius: CGFloat = 0.8
        static let tagOriginY2BoundsHeight: CGFloat = 0.1
        static let titleFontSize2BoundsWidth: CGFloat = 0.070
        static let imageContainerWidth2CardWidth: CGFloat = 0.9
        static let imageContainerHeigh2CardHeight: CGFloat = 0.45
        static let bodyFontSize2BoundsWidth: CGFloat = 0.040
        static let smallLabelGap2BoundsHeight: CGFloat = 0.005
        static let mediumLabelGap2BoundsHeight: CGFloat = 0.01
        static let largeLabelGap2BoundsHeight: CGFloat = 0.02
        static let ExLargeLabelGap2BoundsHeight: CGFloat = 0.05
    }
    
    private var borderLineWidth: CGFloat{
        return 4.0
    }
    
    private var titleFontSize: CGFloat {
        return bounds.width * SizeRatio.titleFontSize2BoundsWidth
    }
    
    private var bodyFontSize: CGFloat {
        return bounds.width * SizeRatio.bodyFontSize2BoundsWidth
    }
    
    private var cardUpperLeft: CGPoint {
        return CGPoint(x: tagSize.width + borderLineWidth / 2, y: borderLineWidth / 2)
    }
    
    private var cardSize: CGSize {
        return CGSize(width: cardWidth, height: cardHeight)
    }
    
    private var cardWidth: CGFloat {
        return bounds.width - 2 * tagSize.width - borderLineWidth
    }
    
    private var cardHeight: CGFloat {
        return bounds.height - borderLineWidth
    }
    
    private var cornerRadius: CGFloat {
        return bounds.width * SizeRatio.cornerRadius2BoundsWidth
    }
    
    private var tagSize: CGSize {
        return CGSize(width: 30, height: 60)
    }
    
    private var tagUpperLeft: CGPoint {
        return CGPoint(x: bounds.width - tagSize.width, y: bounds.height * SizeRatio.tagOriginY2BoundsHeight)
    }
    
    private var tagLowerRight: CGPoint {
        return tagUpperLeft.offset(dx: tagSize.width - borderLineWidth / 2, dy: tagSize.height)
    }
    
    private var labelRect: CGRect {
        return CGRect(
            origin: CGPoint(x: cardUpperLeft.x + SizeRatio.titleOffset2CornerRadius * cornerRadius, y: cardUpperLeft.y + SizeRatio.titleOffset2CornerRadius * cornerRadius),
            size: CGSize(width: cardWidth - 2 * SizeRatio.titleOffset2CornerRadius * cornerRadius, height: cardHeight - 2 * SizeRatio.titleOffset2CornerRadius * cornerRadius))
    }
    private var smallLabelGap: CGFloat {
        return bounds.height * SizeRatio.smallLabelGap2BoundsHeight
    }
    private var mediumLabelGap: CGFloat {
        return bounds.height * SizeRatio.mediumLabelGap2BoundsHeight
    }
    private var largeLabelGap: CGFloat {
        return bounds.height * SizeRatio.largeLabelGap2BoundsHeight
    }
    private var exLargeLabelGap: CGFloat {
        return bounds.height * SizeRatio.ExLargeLabelGap2BoundsHeight
    }
    private var avgCostLabOrigin: CGPoint {
        return CGPoint(x: labelRect.minX, y: titleLab.frame.maxY + mediumLabelGap)
    }
    private var ratingOrigin: CGPoint {
        return CGPoint(x: avgCostLab.frame.minX, y: avgCostLab.frame.maxY)
    }
    private var addressLabOrigin: CGPoint {
        return CGPoint(x: labelRect.minX, y: ratingStarsView.frame.maxY + exLargeLabelGap < 120 ? 120 : ratingStarsView.frame.maxY + exLargeLabelGap)
    }
    private var telLabOrigin: CGPoint {
        return CGPoint(x: labelRect.minX, y: addressLab.frame.maxY + smallLabelGap)
    }
    private var openTimeLabOrigin: CGPoint {
        return CGPoint(x: imageViewsContainer.frame.maxX - openTimeLab.frame.width, y: imageViewsContainer.frame.maxY + smallLabelGap)
    }
    
    private var imageContainerRect: CGRect {
        return CGRect(x: bounds.center.x - SizeRatio.imageContainerWidth2CardWidth * cardWidth / 2, y: telLab.frame.maxY + smallLabelGap, width: SizeRatio.imageContainerWidth2CardWidth * cardWidth, height: SizeRatio.imageContainerHeigh2CardHeight * cardHeight)
    }
    
    private var lightBodyFont: UIFont {
        return UIFont.systemFont(ofSize: bodyFontSize, weight: .light)
    }
    
    private func rightAlignedTitleAttributedText(for text: String) -> NSAttributedString {
        let attributedText = NSMutableAttributedString()
        
        let splitPos = text.firstIndex(of: "(") ?? text.endIndex
        let substring1 = String(text.prefix(upTo: splitPos))
        let scaledTitleFont = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.preferredFont(forTextStyle: .title2).withSize(titleFontSize))
        let titleAttributedText = NSAttributedString(string: substring1, attributes: [.font: scaledTitleFont])
        var scaleFactor:CGFloat = 1.0
        if 1.05 * titleAttributedText.size().width > labelRect.width {
            scaleFactor = labelRect.width / (1.05 * titleAttributedText.size().width)
            let newFont = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.preferredFont(forTextStyle: .title2).withSize(titleFontSize * scaleFactor))
            attributedText.append(NSAttributedString(string: substring1, attributes: [.font: newFont]))
        } else {
            attributedText.append(titleAttributedText)
        }
        
        let substring2 = String(text.suffix(from: splitPos))
        let scaledCaptionFont = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: UIFont.preferredFont(forTextStyle: .caption1).withSize(bodyFontSize * scaleFactor))
        let captionAttributedText = NSMutableAttributedString(string: "\n" + substring2, attributes: [.font: scaledCaptionFont])
        attributedText.append(captionAttributedText)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
        
        return attributedText
    }
    
    private func makeBodyAttributedText(for text: String, _ font: UIFont, _ align: NSTextAlignment = .left) -> NSAttributedString {
        let attributedText = NSMutableAttributedString()
        
        let scaledFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
        let attemptedttributedText = NSAttributedString(string: text, attributes: [.font: scaledFont])
        
        if 1.05 * attemptedttributedText.size().width > labelRect.width {
            let scaleFactor = labelRect.width / (1.05 * attemptedttributedText.size().width)
            let newFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(bodyFontSize * scaleFactor))
            attributedText.append(NSAttributedString(string: text, attributes: [.font: newFont]))
        } else {
            attributedText.append(attemptedttributedText)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = align
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
        
        return attributedText
    }
}
