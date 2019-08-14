//
//  CardListViewController.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/6.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

class CardListViewController: UIViewController, CardListViewDataSource, CardListViewDelegate, POISearchManagerDelegate {
    
    @IBOutlet weak var tipsLabel: UILabel!
    
    var cardListView: CardListView = CardListView()
    
    var restaurants = [Restaurant]()
    
    private lazy var poiSearchManager = { () -> POISearchManager in
        let searcher = POISearchManager()
        searcher.delegate = self
        return searcher
    }()
    
    func onSearchDone(newPois: [AMapPOI], total: Int, first: Bool) {
        if let selectedCardView = selectedCardView, let selectedCardIndex = selectedCardIndex {
            restaurants[selectedCardIndex] = Restaurant(with: newPois[0])
            selectedCardView.setupCard(with: restaurants[selectedCardIndex])
            selectedCardView.loading = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardListView.dataSource = self
        cardListView.cardListDelegate = self
        cardListView.frame = view.bounds
        view.addSubview(cardListView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tipsLabel.isHidden = (restaurants.count > 0)
    }
    
    func numberOfRows() -> Int {
        return restaurants.count
    }
    
    func updateData(for view: RestaurantCardView, at index: Int) {
        view.setupCard(with: restaurants[index])
        view.viewController = self
    }
    
    func didDeleteCard(at row: Int) {
        restaurants.remove(at: row)
    }
    
    private var selectedCardIndex: Int?
    private var selectedCardView: RestaurantCardView?
    func selectCard(at row: Int, for view: RestaurantCardView) {
        selectedCardIndex = row
        selectedCardView = view
        if restaurants[row].openTime == nil {
            view.loading = true
            poiSearchManager.search(for: restaurants[row].uid)
        } else {
            view.setupCard(with: restaurants[row])
        }
        view.images.removeAll()
        restaurants[row].fetchImage { [weak view, weak self] (image) in
            view?.images.append(image)
            if view?.images.count == self?.restaurants[row].images.count {
                view?.setupImages()
            }
        }
    }
    
    func deselectCard(at row: Int, for view: RestaurantCardView) {
        poiSearchManager.cancelAllRequests()
        selectedCardIndex = nil
        selectedCardView = nil
        view.loading = false
    }
    
    
}
