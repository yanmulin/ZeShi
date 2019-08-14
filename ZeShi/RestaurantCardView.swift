//
//  CardView.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/6.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

@IBDesignable
class RestaurantCardView: UIView, UIAlertViewDelegate, UIGestureRecognizerDelegate {
    
    weak var viewController: UIViewController?
    
    var title: String = "" {
        didSet { setNeedsLayout() }
    }
    var titleNote: String = "" {
        didSet { setNeedsLayout() }
    }
    var address: String = "" {
        didSet { setNeedsLayout() }
    }
    var tel = [String]() {
        didSet { setNeedsLayout() }
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
    var type: Restaurant.Genre = .Others {
        didSet { setNeedsLayout() }
    }
    
    var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    
    private lazy var titleLab = makeLabel()
    private lazy var addressBtn = makeButton(#selector(openMap(_:)))
    private lazy var telBtn = makeButton(#selector(call(_:)))
    private lazy var imageViewsContainer = makeImagesContainerView()
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
        view.isHidden = true
        view.frame.size = rect.size
        addSubview(view)
        return view
    }
    
    var loading: Bool = false {
        didSet {
            if loading {
                MBProgressHUD.showAdded(to: self, animated: true)
            } else {
                MBProgressHUD.hide(for: self, animated: true)
            }
        }
    }
    
    func setupCard(with restaraut: Restaurant) {
        title = restaraut.title
        titleNote = restaraut.titleNote
        address = restaraut.address
        tel = restaraut.tel
        rating = restaraut.rating
        avgCost = restaraut.avgCost
        openTime = restaraut.openTime ?? ""
        type = restaraut.type
        
        coordinate = restaraut.coordinate
        
        print("\(restaraut)")
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
    
    func removeAllImages() {
        imageViewsContainer.subviews.forEach { $0.removeFromSuperview() }
        imageViewsContainer.contentSize = CGSize.zero
        imageViewsContainer.contentOffset = CGPoint.zero
    }
    
    var images = [UIImage]()
    func setupImages() {
        imageViewsContainer.subviews.forEach { $0.removeFromSuperview() }
        imageViewsContainer.contentSize = CGSize.zero
        
        if images.count == 0 {
            imageViewsContainer.isHidden = true
            return
        }
        
        images.sort(by: { return $0.size.width > $1.size.width })
        
        func setup(image: UIImage, at origin: CGPoint, _ height: CGFloat) -> CGFloat {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageViewsContainer.addSubview(imageView)
            imageView.isOpaque = false
            let width =  height / image.size.height * image.size.width
            imageView.frame = CGRect(origin: origin, size: CGSize(width: width, height: height))
            return width
        }
        
        var rect = CGRect.zero
        rect.size.height = imageContainerRect.height
        if images.count == 1 {
            rect.size.width += setup(image: images[0], at: rect.origin, imageContainerRect.width * images[0].size.height / images[0].size.width)
        } else {
            rect.size.width += setup(image: images[0], at: rect.origin, imageContainerRect.height)
            for i in stride(from: 1, to: images.count - 1, by: 2) {
                if images[i].size.width == images[i+1].size.width {
                    _ = setup(image: images[i], at: rect.rightTop, imageContainerRect.height / 2)
                    rect.size.width += setup(image: images[i+1], at: rect.rightTop.offset(dx: 0, dy: imageContainerRect.height / 2), imageContainerRect.height / 2)
                } else {
                    rect.size.width += setup(image: images[i], at: rect.rightTop, imageContainerRect.height)
                    rect.size.width += setup(image: images[i+1], at: rect.rightTop, imageContainerRect.height)
                }
            }
            if images.count > 2 && images.count % 2 == 0 {
                rect.size.width += setup(image: images[images.count-1], at: rect.rightTop, imageContainerRect.height)
            }
        }
        
        imageViewsContainer.contentSize = rect.size
        setNeedsLayout()
    }
    
    override func draw(_ rect: CGRect) {
        let cardRect = CGRect(origin: cardUpperLeft, size: cardSize)
        let outline = UIBezierPath(roundedRect: cardRect, cornerRadius: cornerRadius)
        #colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1).setFill()
        #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).setStroke()
        outline.lineJoinStyle = .round
        outline.lineWidth = borderLineWidth
        outline.stroke()
        outline.fill()
        
        let tagPath = UIBezierPath()
        tagPath.move(to: tagLowerRight.offset(dx: -tagSize.width, dy: 0))
        tagPath.addLine(to: tagLowerRight)
        tagPath.addLine(to: tagUpperLeft.offset(dx: tagSize.width-5, dy: 0))
        tagPath.addLine(to: tagUpperLeft.offset(dx: 5, dy: 0))
        tagPath.close()
        tagPath.lineJoinStyle = .round
        tagPath.lineWidth = borderLineWidth
        type.color.setFill()
        tagPath.stroke()
        tagPath.fill()
        
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attemptedAttributedText = NSAttributedString(string: type.rawValue, attributes: [.font: mediumTagFont, .paragraphStyle: paragraphStyle])
        let maxDrawSize = tagSize.offset(dw: -10, dh: -10)
        if 1.1 * attemptedAttributedText.size().width > maxDrawSize.width {
            let scaleFactor = maxDrawSize.width / (1.1 * attemptedAttributedText.size().width)
            let newFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: tagFontSize * scaleFactor))
            let attributedText = NSAttributedString(string: type.rawValue, attributes: [.font: newFont])
            attributedText.draw(at: tagUpperLeft.offset(dx: tagSize.width / 2 - attributedText.size().width / 2, dy: tagSize.height / 2 - attributedText.size().height / 2))
        } else {
            attemptedAttributedText.draw(at: tagUpperLeft.offset(dx: tagSize.width / 2 - attemptedAttributedText.size().width / 2, dy: tagSize.height / 2 - attemptedAttributedText.size().height / 2))
        }
        
        if let image = UIImage(named: "restaraunt-icon") {
            outline.addClip()
            let imageRect = CGRect(x: cardRect.minX - cardRect.width * 0.625, y: cardRect.minY, width: cardRect.height / image.size.height * image.size.width, height: cardRect.height)
            image.draw(in: imageRect, blendMode: .normal, alpha: 0.15)
        }
        
        super.draw(rect)
    }
    
    var row: Int = 0
    
    var isAnimating = false
    private var _propertyAnimator: UIViewPropertyAnimator?
    private var propertyAnimator: UIViewPropertyAnimator?
    
    private func makeLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.isHidden = true
        addSubview(label)
        return label
    }
    
    private func makeButton(_ action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.isHidden = true
        addSubview(button)
        return button
    }
    
    private func makeImagesContainerView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.isHidden = true
//        scrollView.backgroundColor = #colorLiteral(red: 0.8957462427, green: 0.8957462427, blue: 0.8957462427, alpha: 1)
        //        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isUserInteractionEnabled = true
        addSubview(scrollView)
        return scrollView
    }
    
    private func configureLabel(_ label: UILabel, with attributedText: NSAttributedString) {
        label.isHidden = false
        label.attributedText = attributedText
        label.frame.size = label.sizeThatFits(labelRect.size)
    }
    
    private func configureButton(_ button: UIButton, with attributedText: NSAttributedString) {
        button.isHidden = false
        button.frame.size = attributedText.size()
        button.setAttributedTitle(attributedText, for: .normal)
        button.setTitleColor(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1), for: .normal)
    }
    
    private func configureRating(_ rating: CGFloat, with view: UIView, _ label: UILabel) {
        view.isHidden = false
        view.frame.origin = ratingOrigin
//        ratingMaskLayer.frame.origin = ratingOrigin
        ratingMaskLayer.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: ratingOrigin.x + view.frame.width * rating / 5.0, height: bounds.height)).cgPath
        configureLabel(label, with: makeBodyAttributedText(for: rating == 0 ? "未知" : "\(rating)", lightBodyFont))
        ratingLab.frame.origin = CGPoint(x: view.frame.maxX + smallLabelGap, y: view.frame.center.y - ratingLab.frame.height / 2)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        configureLabel(titleLab, with: rightAlignedTitleAttributedText(for: title, titleNote))
        titleLab.frame.origin = labelRect.rightTop.offset(dx: -titleLab.frame.width, dy: 0)
        
        configureLabel(avgCostLab, with: makeBodyAttributedText(for: avgCost == 0 ? "人均 未知" : "人均 ¥\(avgCost)", lightBodyFont))
        avgCostLab.frame.origin = avgCostLabOrigin

        ratingStarsBgView.frame.origin = ratingOrigin
        ratingStarsBgView.isHidden = false
        configureRating(rating, with: ratingStarsView, ratingLab)
        
        if showingDetail {
            configureButton(addressBtn, with: makeBodyAttributedText(for: address, lightBodyFont, .left))
            addressBtn.frame.origin = addressBtnOrigin
            
            configureButton(telBtn, with: makeBodyAttributedText(for: tel.joined(separator: " "), lightBodyFont, .left))
            telBtn.frame.origin = telBtnOrigin
            
            imageViewsContainer.frame = imageContainerRect
            imageViewsContainer.isHidden = (images.count == 0)
            
            if openTime.count > 0 {
                configureLabel(openTimeLab, with: makeBodyAttributedText(for: openTime.hasSuffix("营业") ? openTime : openTime + " 营业", lightBodyFont, .right))
                openTimeLab.frame.origin = openTimeLabOrigin
                openTimeLab.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
        } else {
            addressBtn.isHidden = true
            telBtn.isHidden = true
            imageViewsContainer.isHidden = true
            openTimeLab.isHidden = true
        }
    }
    
    @objc private func call(_ sender: Any) {
        if tel.count == 1 {
            let url = URL(string: "tel:" + tel[0])
            if let url = url, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else if let vc = viewController {
            let actionSheet = UIAlertController(title: "请选择一个呼叫电话", message: nil, preferredStyle: .actionSheet)
            for t in tel {
                let actionItem = UIAlertAction(title: t, style: .default) { (action) in
                    let url = URL(string: "tel:" + action.title!)
                    if let url = url, UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                actionSheet.addAction(actionItem)
            }
            let cancleItem = UIAlertAction(title: "取消", style: .cancel)
            actionSheet.addAction(cancleItem)
            vc.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    @objc private func openMap(_ sender: Any) {
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: [])
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: [])
        if let title = encodedTitle, let address = encodedAddress, let url = URL(string: "http://maps.apple.com/?q=\(title)&address=\(address)&ll=\(coordinate.latitude),\(coordinate.longitude)"),  UIApplication.shared.canOpenURL(url) {
            let alertSheet = UIAlertController(title: "打开Apple地图显示位置", message: nil, preferredStyle: .alert)
            alertSheet.addAction(UIAlertAction(title: "确定", style: .default, handler: { (_) in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }))
            alertSheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            viewController?.present(alertSheet, animated: true, completion: nil)
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        self.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        self.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.layer.shadowOpacity = 0.6
        self.layer.shadowRadius = 3
    }
    
    private(set) var showingDetail: Bool = true {
        didSet { setNeedsLayout() }
    }
    
    func showDetail(_ animated: Bool) {
        showingDetail = true
        if animated {
            animateTilting(from: -CGFloat.pi / 6, to: 0)
        } else {
            layer.transform = CATransform3DIdentity
        }
    }
    
    func dismissDetail(_ animated: Bool) {
        showingDetail = false
        if animated {
            animateTilting(from: 0, to: -CGFloat.pi / 6)
        } else {
            var t = CATransform3DIdentity
            t.m34 = CGFloat(row) * 1e-10 - 1/500
            t = CATransform3DRotate(t, -CGFloat.pi / 6, 1, 0, 0)
            layer.transform = t

        }
    }
    
    private func animateTilting(from: CGFloat, to: CGFloat) {
        layer.removeAnimation(forKey: "tilt-animation")
        let animation = CABasicAnimation(keyPath: "transform.rotation.x")
        animation.fromValue = from
        animation.toValue = to
        animation.duration = 0.5
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        layer.add(animation, forKey: "tilt-animation")
    }
}

extension RestaurantCardView {
    private struct SizeRatio {
        static let cornerRadius2BoundsWidth: CGFloat = 0.05
        static let titleOffset2CornerRadius: CGFloat = 0.8
        static let tagOriginX2BoundsWidth: CGFloat = 0.65
        static let titleFontSize2LabelRectWidth: CGFloat = 0.09
        static let bodyFontSize2LabelRectWidth: CGFloat = 0.07
        static let tagFontSize2LabelRectWidth: CGFloat = 0.060
        static let imageContainerWidth2CardWidth: CGFloat = 0.9
        static let imageContainerHeigh2Width: CGFloat = 0.65
        static let smallLabelGap2BoundsHeight: CGFloat = 0.005
        static let mediumLabelGap2BoundsHeight: CGFloat = 0.01
        static let largeLabelGap2BoundsHeight: CGFloat = 0.02
        static let ExLargeLabelGap2BoundsHeight: CGFloat = 0.05
    }
    
    private var borderLineWidth: CGFloat{
        return 3
    }
    
    private var titleFontSize: CGFloat {
        return labelRect.width * SizeRatio.titleFontSize2LabelRectWidth
    }
    
    private var bodyFontSize: CGFloat {
        return labelRect.width * SizeRatio.bodyFontSize2LabelRectWidth
    }
    
    private var tagFontSize: CGFloat {
        return bounds.width * SizeRatio.tagFontSize2LabelRectWidth
    }
    
    private var lightBodyFont: UIFont {
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: bodyFontSize, weight: .light))
    }
    private var mediumTagFont: UIFont {
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: tagFontSize))
    }
    
    private var cardUpperLeft: CGPoint {
        return CGPoint(x: borderLineWidth / 2, y: tagSize.height + borderLineWidth / 2)
    }
    
    private var cardSize: CGSize {
        return CGSize(width: cardWidth, height: cardHeight)
    }
    
    private var cardWidth: CGFloat {
        return bounds.width - borderLineWidth
    }
    
    private var cardHeight: CGFloat {
        return bounds.height - borderLineWidth - tagSize.height
    }
    
    private var cornerRadius: CGFloat {
        return bounds.width * SizeRatio.cornerRadius2BoundsWidth
    }
    
    private var tagSize: CGSize {
        return CGSize(width: 65, height: 30)
    }
    
    private var tagUpperLeft: CGPoint {
        return CGPoint(x: bounds.width * SizeRatio.tagOriginX2BoundsWidth, y: borderLineWidth / 2)
    }
    
    private var tagLowerRight: CGPoint {
        return tagUpperLeft.offset(dx: tagSize.width, dy: tagSize.height - borderLineWidth / 2)
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
    private var addressBtnOrigin: CGPoint {
        return CGPoint(x: labelRect.minX, y: ratingStarsView.frame.maxY + exLargeLabelGap < 120 ? 120 : ratingStarsView.frame.maxY + exLargeLabelGap)
    }
    private var telBtnOrigin: CGPoint {
        return CGPoint(x: labelRect.minX, y: addressBtn.frame.maxY + smallLabelGap)
    }
    private var openTimeLabOrigin: CGPoint {
        return images.count == 0 ? CGPoint(x: telBtn.frame.minX, y: telBtn.frame.maxY) : CGPoint(x: imageViewsContainer.frame.maxX - openTimeLab.frame.width, y: imageViewsContainer.frame.maxY + smallLabelGap)
    }
    
    private var imageContainerRect: CGRect {
        return images.count == 0 ? CGRect.zero : CGRect(x: cardUpperLeft.x + (cardWidth - SizeRatio.imageContainerWidth2CardWidth * cardWidth) / 2, y: telBtn.frame.maxY + smallLabelGap, width: SizeRatio.imageContainerWidth2CardWidth * cardWidth, height: SizeRatio.imageContainerHeigh2Width * SizeRatio.imageContainerWidth2CardWidth * cardWidth)
    }
    
    private func rightAlignedTitleAttributedText(for title: String, _ note: String) -> NSAttributedString {
        let attributedText = NSMutableAttributedString()
        
        
        let scaledTitleFont = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.preferredFont(forTextStyle: .title2).withSize(titleFontSize))
        let titleAttributedText = NSAttributedString(string: title, attributes: [.font: scaledTitleFont])
        var scaleFactor:CGFloat = 1.0
        if 1.05 * titleAttributedText.size().width > labelRect.width {
            scaleFactor = labelRect.width / (1.05 * titleAttributedText.size().width)
            let newFont = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.preferredFont(forTextStyle: .title2).withSize(titleFontSize * scaleFactor))
            attributedText.append(NSAttributedString(string: title, attributes: [.font: newFont]))
        } else {
            attributedText.append(titleAttributedText)
        }
        

        let scaledCaptionFont = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: UIFont.preferredFont(forTextStyle: .caption1).withSize(bodyFontSize * scaleFactor))
        let captionAttributedText = NSMutableAttributedString(string: "\n" + note, attributes: [.font: scaledCaptionFont])
        attributedText.append(captionAttributedText)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
        
        return attributedText
    }
    
    private func makeBodyAttributedText(for text: String, _ font: UIFont, _ align: NSTextAlignment = .left) -> NSAttributedString {
        let attributedText = NSMutableAttributedString()
        
        let attemptedttributedText = NSAttributedString(string: text, attributes: [.font: font])
        
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
