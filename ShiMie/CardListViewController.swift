//
//  CardListViewController.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/6.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

class CardListViewController: UIViewController, CardListViewDataSource, CardListViewDelegate {
    
    var cardListView: CardListView = CardListView()
    var cardViews = [RestaurantCardView]()
    
    // Models
    private var restaurants = [Restaurant]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardListView.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
        cardListView.headerSpace = view.bounds.height / 3
        cardListView.dataSource = self
        cardListView.cardListDelegate = self
        cardListView.frame = view.bounds
        view.addSubview(cardListView)
        for i in 0..<20 {
            var r = Restaurant()
            r.number = i
            restaurants.append(r)
        }
    }
    
    func numberOfRows() -> Int {
        return restaurants.count
    }
    
    func updateData(for view: RestaurantCardView, at index: Int) {
        view.number = restaurants[index].number
        view.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        view.layer.borderColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
        view.layer.borderWidth = 5.0
        view.layer.cornerRadius = 12.0
        view.isRolling = true
    }
    
    func didDeleteCard(at row: Int) {
        restaurants.remove(at: row)
    }
    
}
