//
//  WaveTestVC.swift
//  ShiMie
//
//  Created by 颜木林 on 2019/8/8.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import UIKit

class RestaurantDetailViewController: UIViewController, POISearchManagerDelegate {
    
    var restaraut: Restaurant! {
        didSet {
            poiSearchManager.search(for: restaraut.uid);
        }
    }
    
    private lazy var poiSearchManager: POISearchManager = { () -> POISearchManager in
        let searcher = POISearchManager()
        searcher.delegate = self
        return searcher
    }()
    
    func onSearchDone(newPois: [AMapPOI], total: Int, first: Bool) {
        assert(newPois.count > 0)
        cardView.loading = false
        cardView.setupCard(with: Restaurant(with: newPois[0]))
    }
    
    @IBOutlet weak var cardView: RestaurantCardView!
    
    @IBOutlet weak var triggerButton: UIButton! {
        didSet {
            triggerButton.layer.cornerRadius = triggerButton.bounds.width / 2
            triggerButton.layer.shadowColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            triggerButton.layer.shadowOffset = CGSize(width: 1, height: 1)
            triggerButton.layer.shadowRadius = 2.0
        }
    }
    
    @IBAction func trigger(_ sender: Any) {
        let presentingViewController = self.presentingViewController?.contentVC
        self.dismiss(animated: true, completion: {
            presentingViewController?.performSegue(withIdentifier: "showDetail", sender: presentingViewController)
        })
    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardView.loading = true
        cardView.viewController = self
        cardView.removeAllImages()
        restaraut.fetchImage { [weak cardView, weak self] (image) in
            cardView?.images.append(image)
            if cardView?.images.count == self?.restaraut.images.count {
                cardView?.setupImages()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cardView.isHidden = true
        cardView.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cardView.isHidden = false
        view.bringSubviewToFront(cardView)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5,
                                                       delay: 0.0,
                                                       options: .curveEaseOut,
                                                       animations: {
                                                        self.cardView.transform = CGAffineTransform.identity
        })

    }


    
    

}
