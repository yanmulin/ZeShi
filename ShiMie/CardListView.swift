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
}

class CardListView: UIScrollView, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    var cardViewType = RestaurantCardView.self
    var headerSpace: CGFloat = 250
    var cardGap: CGFloat = kCardDefault.cardGap
    var cardWidth: CGFloat = kCardDefault.cardWidth
    var cardHeight: CGFloat = kCardDefault.cardHeight
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
                toggleDetailModeFor(view: view, animated: false)
            } else {
                contentOffset.y = view.center.y-bounds.height/2
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
        let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        cardView.addGestureRecognizer(pan)
        pan.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        tap.require(toFail: panGestureRecognizer)
        cardView.addGestureRecognizer(tap)
        return cardView
    }
    
    private var tapTimestamp: TimeInterval = 0
    private var tapCardEnabled = true
    private var showingDetail: Int?
    var propertyAnimator: UIViewPropertyAnimator?
    
    @objc private func tap(_ gr: UITapGestureRecognizer) {
        print("tap, contentOffset.y=\(self.contentOffset.y)")
        let curTimestamp = Date.timeIntervalSinceReferenceDate
        if curTimestamp - tapTimestamp > 2 * CardListView.defaultAnimateDuration && tapCardEnabled {
            tapTimestamp = curTimestamp
            if let view = gr.view as? RestaurantCardView {
                toggleDetailModeFor(view: view, animated: true)
            }
        }
            
    }
    
    private var deletingCards = Set<RestaurantCardView>()
    private var animatingCards: [RestaurantCardView] {
        return cachedCells.values.filter{ return $0.isAnimating }
    }
    
    @objc private func pan(_ gr: UIPanGestureRecognizer) {
        
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
                    if abs(velocity.x) > abs(velocity.y) * 2 && abs(translation.x) > bounds.width / 3 && abs(gr.velocity(in: self).x) > 400 {
                        deletingCards.insert(view)
                        let row = view.row
                        cachedCells.removeValue(forKey: row)
                        view.isAnimating = true
                        print("delete row \(row) card#\(view.number)")
                        view.propertyAnimator = UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: CardListView.defaultAnimateDuration,
                            delay: 0.0,
                            options: .curveEaseIn,
                            animations: {
                                if gr.velocity(in: self).x > 0 {
                                    view.center.x =  self.bounds.width + self.cardWidth
                                    view.transform = CGAffineTransform.identity.rotated(by: -CGFloat.pi / 6)
                                } else {
                                    view.center.x =  -self.cardWidth
                                    view.transform = CGAffineTransform.identity.rotated(by: CGFloat.pi / 6)
                                }
                                view.center.y += 200
                        },completion: { (_) in
                            print("complete card#\(view.number) deleted")
                            view.removeFromSuperview()
                            self.reusableCells.append(view)
                            self.tapCardEnabled = true
                        })
                        if showingDetail != nil {
                            toggleDetailModeFor(view: view, animated: true)
                        } else {
                            if (row < numberOfRows - 1) {
                                let movingUpCards = cachedCells.filter({ $0.key > row }).values.sorted(by: { return $0.number < $1.number })
                                movingUpCards.forEach { $0.isAnimating = true; self.cachedCells[$0.row]=nil; $0.row-=1; self.cachedCells[$0.row]=$0 }
                                let completion = { (_: UIViewAnimatingPosition) in
                                    if let cardView = movingUpCards.first {
//                                        let aboveDeletingCount = self.deletingCards.filter { $0.row < cardView.row }.count
                                        if cardView.center == self.rect(for: cardView.row).center && self.deletingCards.count > 0 {
                                            movingUpCards.forEach{ $0.isAnimating = false; $0.propertyAnimator = nil }
                                            self.deletingCards.removeAll()
                                            self.propertyAnimator = nil
                                            print("complete card#\(cardView.number) moving up since card#\(view.number) was deleted")
                                        } else {
                                            print("still moving card#\(cardView.number) up since card#\(view.number) was deleted, get \(self.deletingCards.count) deleted cards")
                                        }
                                        
                                    }
                                }
                                if let animator = propertyAnimator, animator.state == .active {
                                    animator.addCompletion({ (_) in
                                        UIViewPropertyAnimator.runningPropertyAnimator(
                                        withDuration: CardListView.defaultAnimateDuration,
                                        delay: 0.0,
                                        options: [.curveEaseInOut, .allowUserInteraction],
                                        animations: {
                                            print("moving up")
                                            movingUpCards.forEach{ $0.center.y -= self.cardGap }
                                        },completion: completion)
                                    })
                                } else {
                                    propertyAnimator = UIViewPropertyAnimator.runningPropertyAnimator(
                                        withDuration: CardListView.defaultAnimateDuration,
                                        delay: 0.0,
                                        options: [.curveEaseInOut, .allowUserInteraction],
                                        animations: {
                                            print("moving up")
                                            movingUpCards.forEach{ $0.center.y -= self.cardGap }
                                    },completion: completion)
                                }
                            }
                        }
                        self.cardListDelegate?.didDeleteCard(at: row)
                        self.reloadData()
                        if row > numberOfRows - screenCardCount / 2 - 1 {
                            setContentOffset(contentOffset.offset(0, -self.cardGap), animated: true)
                        }

                    } else {
                        tapCardEnabled = true
                        let rowRect = rect(for: view.row)
                        view.isAnimating = true
                        view.propertyAnimator = UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: CardListView.defaultAnimateDuration,
                            delay: 0.0,
                            options: [.curveEaseIn, .allowUserInteraction] ,
                            animations: {
                                view.center.x = rowRect.center.x
                            },completion: { (_) in
                                view.isAnimating = false
                                view.propertyAnimator = nil
                            })
                    }
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
                        preView.propertyAnimator = UIViewPropertyAnimator.runningPropertyAnimator(
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
            view.tilt(to: CGFloat.zero, animated: animated)
            if animated {
                view.isAnimating = true
                view.propertyAnimator = UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: CardListView.defaultAnimateDuration,
                    delay: 0.1,
                    options: .curveEaseInOut,
                    animations: {
                        view.center.y = self.contentOffset.y + self.bounds.height / 2
                })
            } else {
                view.center.y = self.contentOffset.y + self.bounds.height / 2
            }
            for row in view.row+1..<view.row+cachedCells.count {
                if let postView = cachedCells[row] {
                    if animated {
                        postView.isAnimating = true
                        postView.propertyAnimator = UIViewPropertyAnimator.runningPropertyAnimator(
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
                            preView.propertyAnimator = nil
                        })
                    } else {
                        preView.center.y += self.bounds.height + self.cardHeight
                    }
                }
            }
            if !deletingCards.contains(view) {
                let rowRect = rect(for: view.row)
                if animated {
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: CardListView.defaultAnimateDuration,
                        delay: 0.1,
                        options: .curveEaseInOut,
                        animations: {
                            view.frame = rowRect
                    }, completion: { (_) in
                        view.isAnimating = false
                        view.propertyAnimator = nil
                    })
                } else {
                    view.frame = rowRect
                }
                view.tilt(to: -CGFloat.pi / 6, animated: animated)
            }
            for row in view.row+1..<view.row+cachedCells.count {
                if let postView = cachedCells[row] {
                    //                            postView.isHidden = false
                    let rowRect = deletingCards.contains(view) ? rect(for: row-1) : rect(for: row)
                    if animated {
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: CardListView.defaultAnimateDuration * 2,
                            delay: 0.0,
                            options: .curveEaseOut,
                            animations: {
                                postView.center.y = rowRect.center.y
                        }, completion: { (_) in
                            postView.isAnimating = false
                            postView.propertyAnimator = nil
                        })
                    } else {
                        postView.center.y = rowRect.center.y
                    }
                }
            }
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
                if view.isAnimating == false && view.propertyAnimator == nil {
                    let savedViewCenter = view.center
                    view.frame = rowRect
                    if let state = view.gestureRecognizers?.first?.state, state == .changed {
                        view.center = savedViewCenter
                    }
                    view.row = i
//                    print("layoutListView: card#\(view.number) x=\(view.frame.origin.x)")
                    view.zDistance = kCardDefault.firstZDistance - CGFloat(i) * kCardDefault.deltaZDistance
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
        view.propertyAnimator = nil
        view.isHidden = false
        dataSource?.updateData(for: view, at: index)
        let cardViews = subviews.filter({ return $0.isKind(of: RestaurantCardView.self) }).map({ return $0 as! RestaurantCardView })
        let sameNumberViews = cardViews.filter({ $0.number == view.number && $0 != view }).map { return $0.row }
        print("row: \(index), number: \(view.number), others: \(sameNumberViews)")
        assert(sameNumberViews.count == 0)
        for cardView in cachedCells.values {
            assert(view.number != cardView.number)
        }
        return view
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension CardListView {
    struct kCardDefault {
        static let cardHeight : CGFloat = 350
        static let cardWidth : CGFloat = 230
        static let cardGap : CGFloat = 150
        static let firstZDistance: CGFloat = 1/500
        static let deltaZDistance: CGFloat = 1e-10
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
