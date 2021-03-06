//
//  CardListView.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/12.
//  Copyright © 2019 yanmulin. All rights reserved.
//

// ref: https://github.com/BigZaphod/Chameleon/blob/master/UIKit/Classes/UITableView.m

import UIKit

protocol CardListViewDataSource: class {
    func numberOfRows() -> Int
    func updateData(for view: RestaurantCardView, at index: Int)
    
}

protocol CardListViewDelegate: class {
    func didDeleteCard(at row: Int)
    func selectCard(at row: Int, for view: RestaurantCardView)
    func deselectCard(at row: Int, for view: RestaurantCardView)
}

class CardListView: UIScrollView, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    var cardViewType = RestaurantCardView.self
    weak var dataSource: CardListViewDataSource?
    weak var cardListDelegate: CardListViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.delegate = self
        delegate = self
        self.setNeedsReload()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        print("did scroll to \(contentOffset)")
//        print("didScroll: card#\(cachedCells[0]?.number ?? -1) x=\(cachedCells[0]?.frame.origin.x ?? -1)")
        if let row = showingDetail, let view = cachedCells[row] {
            let translation = panGestureRecognizer.translation(in: self)
            if abs(translation.y) > 10 * abs(translation.x) {
                toggleDetailModeFor(view: view, animated: true)
                dismissDetailModeButton.isHidden = true
            } else {
                contentOffset.y = bigScreen ? view.center.y - bounds.height / 2 : view.center.y - bounds.height + 150 + cardHeight / 2
            }
        }
    }
    
    func setNeedsReload() {
        needsReload = true
        setNeedsLayout()
    }
    
    func reload() {
        cachedCells.values.forEach { $0.removeFromSuperview() }
        reusableCells.forEach { $0.removeFromSuperview() }
        cachedCells.removeAll()
        reusableCells.removeAll()
        
        
        numberOfRows = dataSource?.numberOfRows() ?? 0
        contentSize = CGSize(width: bounds.width, height: CGFloat(numberOfRows) * cardGap + headerSpace + cardHeight)
        
        needsReload = false
    }
    
    func reloadData() {
        numberOfRows = dataSource?.numberOfRows() ?? 0
        contentSize = CGSize(width: bounds.width, height: CGFloat(numberOfRows) * cardGap + headerSpace + cardHeight)
        setNeedsLayout()
    }
    
    private var cachedCells = [Int: RestaurantCardView]()
    private var reusableCells = [RestaurantCardView]()
    
    private lazy var numberOfRows = dataSource?.numberOfRows() ?? 0
    private var needsReload = false
    
    private var visibleBounds: CGRect {
        return CGRect(x: contentOffset.x, y: contentOffset.y-bounds.height, width: bounds.width, height: bounds.height * 3)
    }
    
    override func layoutSubviews() {
        reloadIfNeeded()
        layoutListView()
        super.layoutSubviews()
    }
    
    private func reloadIfNeeded() {
        if needsReload {
            reload()
        }
    }
    
    private func makeCardView() -> RestaurantCardView {
        let cardView = cardViewType.init()
//        let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
//        cardView.addGestureRecognizer(pan)
//        pan.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        tap.require(toFail: panGestureRecognizer)
        cardView.addGestureRecognizer(tap)
        return cardView
    }
    
    private var tapTimestamp: TimeInterval = 0
    private var tapCardEnabled = true
    private var showingDetail: Int?
    
    private lazy var dismissDetailModeButton: UIButton = { () -> UIButton in
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "dismiss"), for: .normal)
//        button.layer.shadowOffset = CGSize(width: 2, height: 2)
//        button.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
//        button.layer.shadowRadius = 2
//        button.layer.shadowOpacity = 0.6
        addSubview(button)
        button.sizeToFit()
//        button.backgroundColor = #colorLiteral(red: 0.9725490196, green: 0.2156862745, blue: 0.04705882353, alpha: 1)
        button.center = CGPoint(x: bounds.center.x, y: bounds.height + 50)
        button.isHidden = true
        button.addTarget(self, action: #selector(dismissDetailMode(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc private func dismissDetailMode(_ sender: Any) {
        if let showingDetail = showingDetail, let view = cachedCells[showingDetail] {
            view.gestureRecognizers?.forEach { $0.isEnabled = true }
            toggleDetailModeFor(view: view, animated: true)
            dismissDetailModeButton.isEnabled = false
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: CardListView.defaultAnimateDuration, delay: 0.0, options: .curveEaseIn, animations: {
                self.dismissDetailModeButton.center.y = self.contentOffset.y + self.bounds.height + 80
            }) { (_) in
                self.dismissDetailModeButton.isHidden = true
            }
            
        }
    }
    
    @objc private func tap(_ gr: UITapGestureRecognizer) {
        print("tap, contentOffset.y=\(self.contentOffset.y)")
        let curTimestamp = Date.timeIntervalSinceReferenceDate
        if curTimestamp - tapTimestamp > 2 * CardListView.defaultAnimateDuration && tapCardEnabled {
            tapTimestamp = curTimestamp
            if let view = gr.view as? RestaurantCardView, view.showingDetail == false {
                view.gestureRecognizers?.forEach { $0.isEnabled = false }
                toggleDetailModeFor(view: view, animated: true)
                dismissDetailModeButton.isHidden = false
                dismissDetailModeButton.isEnabled = true
                self.dismissDetailModeButton.center.y = contentOffset.y + bounds.height + 80
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: CardListView.defaultAnimateDuration, delay: 0.0, options: .curveEaseIn, animations: {
                    self.dismissDetailModeButton.center.y = self.contentOffset.y + self.bounds.height - 80
                })
            }
        }
        
    }
    
//    private var deletingCards = Set<RestaurantCardView>()
    private var animatingCards: [RestaurantCardView] {
        return cachedCells.values.filter{ return $0.isAnimating }
    }
    
    // 左右滑动的删除手势，可能影响性能，暂不用
    var propertyAnimator: UIViewPropertyAnimator?
    @objc private func pan(_ gr: UIPanGestureRecognizer) {
        if showingDetail != nil { return }
        if let view = gr.view as? RestaurantCardView {
            let translation = gr.translation(in: self)
            let velocity = gr.velocity(in: self)
//        print("pan view #\(view.number)")
            switch gr.state {
                case .began: tapCardEnabled = false
                case .changed:
                    if abs(velocity.x) > abs(velocity.y) && abs(translation.x) > abs(translation.y) {
                        view.center.x = defaultCardCenterX + translation.x;
                    }
//                    print("pan: card#\(cachedCells[0]?.number ?? -1) x=\(cachedCells[0]?.frame.origin.x ?? -1), translation.x=\(translation.x)")
                    if abs(translation.x) > bounds.width * 2 / 3 {
                        gr.state = .cancelled
                    }
                case .cancelled, .ended:
//                    if abs(velocity.x) > abs(velocity.y) * 2 && abs(translation.x) > bounds.width / 3 && abs(gr.velocity(in: self).x) > 400 {
//                        deletingCards.insert(view)
//                        let row = view.row
//                        cachedCells.removeValue(forKey: row)
//                        view.isAnimating = true
//                        UIViewPropertyAnimator.runningPropertyAnimator(
//                            withDuration: CardListView.defaultAnimateDuration,
//                            delay: 0.0,
//                            options: .curveEaseIn,
//                            animations: {
//                                if gr.velocity(in: self).x > 0 {
//                                    view.center.x =  self.bounds.width + self.cardWidth
//                                    view.transform = CGAffineTransform.identity.rotated(by: -CGFloat.pi / 6)
//                                } else {
//                                    view.center.x =  -self.cardWidth
//                                    view.transform = CGAffineTransform.identity.rotated(by: CGFloat.pi / 6)
//                                }
//                                view.center.y += 200
//                        },completion: { (_) in
//                            view.removeFromSuperview()
//                            self.reusableCells.append(view)
//                            self.tapCardEnabled = true
//                        })
//                        let movingUpCards = cachedCells.filter({ $0.key > row }).values.sorted(by: { return $0.row < $1.row })
//                        movingUpCards.forEach { $0.isAnimating = true; self.cachedCells[$0.row]=nil; $0.row-=1; self.cachedCells[$0.row]=$0 }
//                        if showingDetail != nil {
//                            toggleDetailModeFor(view: view, animated: true)
//                        } else {
//                            if (row < numberOfRows - 1) {
//                                let completion = { (_: UIViewAnimatingPosition) in
//                                    if let cardView = movingUpCards.first {
////                                        let aboveDeletingCount = self.deletingCards.filter { $0.row < cardView.row }.count
//                                        if cardView.center == self.rect(for: cardView.row).center && self.deletingCards.count > 0 {
//                                            movingUpCards.forEach{ $0.isAnimating = false;
//                                            }
//                                            self.deletingCards.removeAll()
//                                            self.propertyAnimator = nil
//                                        }
//
//                                    }
//                                }
//                                if let animator = propertyAnimator, animator.state == .active {
//                                    animator.addCompletion({ (_) in
//                                        UIViewPropertyAnimator.runningPropertyAnimator(
//                                        withDuration: CardListView.defaultAnimateDuration,
//                                        delay: 0.0,
//                                        options: [.curveEaseInOut, .allowUserInteraction],
//                                        animations: {
//                                            print("moving up")
//                                            movingUpCards.forEach{ $0.center.y -= self.cardGap }
//                                        },completion: completion)
//                                    })
//                                } else {
//                                    propertyAnimator = UIViewPropertyAnimator.runningPropertyAnimator(
//                                        withDuration: CardListView.defaultAnimateDuration,
//                                        delay: 0.0,
//                                        options: [.curveEaseInOut, .allowUserInteraction],
//                                        animations: {
//                                            print("moving up")
//                                            movingUpCards.forEach{ $0.center.y -= self.cardGap }
//                                    },completion: completion)
//                                }
//                            }
//                        }
//                        self.cardListDelegate?.didDeleteCard(at: row)
//                        self.reloadData()
//                        if row > numberOfRows - screenCardCount / 2 - 1 {
//                            setContentOffset(contentOffset.offset(dx: 0, dy: -self.cardGap), animated: true)
//                        }
//
//                    } else {
                        tapCardEnabled = true
                        let rowRect = rect(for: view.row)
                        view.isAnimating = true
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: CardListView.defaultAnimateDuration,
                            delay: 0.0,
                            options: [.curveEaseIn, .allowUserInteraction] ,
                            animations: {
                                view.frame = rowRect
                            },completion: { (_) in
                                view.isAnimating = false
                            })
//                    }
                default: assert(false)
            }
        }
    }
    
    private func toggleDetailModeFor(view: RestaurantCardView, animated: Bool) {
        if showingDetail == nil {
            showingDetail = view.row
            for row in view.row-cachedCells.count..<view.row {
                if let preView = cachedCells[row] {
                    if animated {
                        preView.isAnimating = true
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: CardListView.defaultAnimateDuration * 2,
                            delay: 0.0,
                            options: .curveEaseIn,
                            animations: {
                                preView.center.y -= self.bounds.height + self.cardHeight
                        }, completion: { (_) in
    //                          preView.isHidden = true
                        })
                    } else {
                        preView.center.y -= self.bounds.height + self.cardHeight
                    }
                }
            }
            view.showDetail(animated)
            if animated {
                view.isAnimating = true
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: CardListView.defaultAnimateDuration,
                    delay: 0.1,
                    options: .curveEaseInOut,
                    animations: {
                        view.center.y = self.detailModeCardCenter.y
                })
            } else {
                view.center.y = detailModeCardCenter.y
            }
            for row in view.row+1..<view.row+cachedCells.count {
                if let postView = cachedCells[row] {
                    if animated {
                        postView.isAnimating = true
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: CardListView.defaultAnimateDuration * 2,
                            delay: 0.0,
                            options: .curveEaseIn,
                            animations: {
                                postView.center.y += self.bounds.height + self.cardHeight
                        }, completion: { (_) in
                            //                                    postView.isHidden = true
                        })
                    } else {
                        postView.center.y += self.bounds.height + self.cardHeight
                    }
                }
            }
            cardListDelegate?.selectCard(at: view.row, for: view)
        } else {
            showingDetail = nil
            for row in view.row-cachedCells.count..<view.row {
                if let preView = cachedCells[row] {
                    //                            preView.isHidden = false
                    if animated {
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: CardListView.defaultAnimateDuration * 2,
                            delay: 0.0,
                            options: .curveEaseOut,
                            animations: {
                                preView.center.y += self.bounds.height + self.cardHeight
                        }, completion: { (_) in
                            preView.isAnimating = false
                        })
                    } else {
                        preView.center.y += self.bounds.height + self.cardHeight
                    }
                }
            }
            
//            if !deletingCards.contains(view) {
                let rowRect = rect(for: view.row)
                if animated {
                    view.isAnimating = true
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: CardListView.defaultAnimateDuration,
                        delay: 0.1,
                        options: .curveEaseInOut,
                        animations: {
                            view.frame = rowRect
                    }, completion: { (_) in
                        view.isAnimating = false
                    })
                } else {
                    view.center = rowRect.center
                }
                view.dismissDetail(animated)
//            }
//            let startRow = !deletingCards.contains(view) ? view.row+1 : view.row
            let startRow = view.row+1
            for row in startRow..<view.row+cachedCells.count {
                if let postView = cachedCells[row] {
                    //                            postView.isHidden = false
                    
                    let rowRect = rect(for: row)
                    if animated {
                        postView.isAnimating = true
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: CardListView.defaultAnimateDuration * 2,
                            delay: 0.0,
                            options: .curveEaseOut,
                            animations: {
                                postView.center.y = rowRect.center.y
                        }, completion: { (_) in
                            postView.isAnimating = false
                        })
                    } else {
                        postView.center.y = rowRect.center.y
                    }
                }
            }
            cardListDelegate?.deselectCard(at: view.row, for: view)
        }
    }
    
    private func layoutListView() {
        if showingDetail != nil {
            return
        }
        var availableCells = cachedCells
        cachedCells.removeAll()
        for i in 0..<numberOfRows {
            let rowRect = rect(for: i)
            if visibleBounds.intersects(rowRect) {
                let view = availableCells[i] ?? dequeueReusableView(at: i)
                if view.isAnimating == false  {
                    let savedViewCenter = view.center
                    view.frame = rowRect
                    if let state = view.gestureRecognizers?.first?.state, state == .changed {
                        view.center = savedViewCenter
                    }
                    view.row = i
                    view.dismissDetail(false)
                }

                
                addSubview(view)
                cachedCells.updateValue(view, forKey: i)
                availableCells.removeValue(forKey: i)
            }
        }
        
        for view in availableCells.values {
            reusableCells.append(view)
            view.removeFromSuperview()
        }
    }
    
    private func dequeueReusableView(at index: Int) -> RestaurantCardView {
        let view = reusableCells.popLast() ?? makeCardView()
        view.frame.origin.x = defaultCardPosX
        view.isAnimating = false
        view.isHidden = false
        view.removeAllImages()
        dataSource?.updateData(for: view, at: index)
        return view
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension CardListView {
    struct SizeRatio {
        static let cardGap2BoundsHeight : CGFloat = 0.20
        static let headerSpace2BoundsHeight : CGFloat = 0.30
    }
    
    var cardGap: CGFloat {
        return bounds.height * SizeRatio.cardGap2BoundsHeight
    }
    var cardHeight: CGFloat {
        return cardWidth * 1.5
    }
    var headerSpace: CGFloat {
        return bounds.height * SizeRatio.headerSpace2BoundsHeight
    }
    
    var cardWidth: CGFloat {
        return bounds.width * 0.75
    }
    
    var bigScreen: Bool {
        return (bounds.height - cardHeight) / 2 - 150 > 0
    }
    
    var detailModeCardCenter: CGPoint {
        return bigScreen ? CGPoint(x: bounds.center.x, y: contentOffset.y + bounds.height/2) : CGPoint(x: bounds.center.x, y: contentOffset.y + bounds.height - cardHeight / 2 - 150)
    }
    
    var defaultCardPosX: CGFloat {
        return (bounds.width - cardWidth) / 2
    }
    
    var defaultCardCenterX: CGFloat {
        return bounds.width / 2
    }
    
    var screenCardCount: Int {
        return Int(bounds.height / cardGap)
    }
    
    func rect(for index: Int) -> CGRect {
        let x = defaultCardPosX
        let y = CGFloat(index) * cardGap + headerSpace
        return CGRect(x: x, y: y, width: cardWidth, height: cardHeight)
    }
    
    // Tricks: 把动画时间调慢可以发现很多动画间冲突的bug
    static let defaultAnimateDuration: TimeInterval =  0.3
        
}
