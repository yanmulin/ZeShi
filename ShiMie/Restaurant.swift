//
//  Restaurant.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/6.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import Foundation

struct Restaurant {
    var uid: String = ""
    var coordinate = kCLLocationCoordinate2DInvalid
    var title: String = ""
    var titleNote: String = ""
    var address: String = ""
    var tel = [String]()
    var images = [(title: String, url: URL?)]()
    var openTime: String?
    var rating: CGFloat = 0.0
    var avgCost: CGFloat = 0
    var type: Genre = .Others
    
    
    init(with poi: AMapPOI) {
        if let latitude = poi.location?.latitude, let longitude = poi.location?.longitude {
            coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(latitude), CLLocationDegrees(longitude))
        }
        uid = poi.uid
        let splitPos = poi.name.firstIndex(of: "(") ?? poi.name.endIndex
        title = String(poi.name.prefix(upTo: splitPos))
        titleNote = String(poi.name.suffix(from: splitPos))
        address = poi.address
        tel = poi.tel.split(separator: ";").map { String($0).trimmingCharacters(in: CharacterSet(charactersIn: " ")) }
        poi.images.forEach { images.append(($0.title, URL(string: $0.url)))}
        avgCost = poi.extensionInfo.cost
        openTime = poi.extensionInfo.openTime
        rating = poi.extensionInfo.rating
        type =  Genre(with: poi.type)
        if (type == .Others ) {
            print("\(title):\(poi.type ?? "null")")
        }
    }
    
    func fetchImage(_ completion: ((UIImage)->Void)?) {
        for (_, url) in images {
            if let url = url {
                DispatchQueue.global(qos: .userInitiated).async {
                    let urlContents = try? Data(contentsOf: url)
                    DispatchQueue.main.async {
                        if let completion = completion, let imageData = urlContents, let image = UIImage(data: imageData) {
                            completion(image)
                        }
                    }
                }
            }
        }
    }
    
    init() {}
}

extension Restaurant {
    enum Genre: String {
        case Chinese = "中餐厅", HotPot = "火锅", Western = "西餐厅", Steak = "扒房", Japanese = "日本料理", Korean = "韩国料理", FastFood = "快餐厅", Leisure = "休闲餐饮场所", Cafe = "咖啡厅", Tea = "茶艺馆", ColdDrink = "冷饮店", Cake = "蛋糕店", Desert = "甜品店", Others = "其他"
        
        var color: UIColor {
            switch self {
            case .Chinese: return #colorLiteral(red: 0.06192067666, green: 0.7931523677, blue: 1, alpha: 1)
            case .Western: return #colorLiteral(red: 1, green: 0.5503063464, blue: 0.8944409966, alpha: 1)
            case .Steak: return #colorLiteral(red: 0.7254902124, green: 0.6065132181, blue: 0.2010999904, alpha: 1)
            case .Japanese: return #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
            case .Korean: return #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
            case .FastFood: return #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
            case .Leisure: return #colorLiteral(red: 0.7347321714, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
            case .Cafe: return #colorLiteral(red: 0.7880875895, green: 0.6095141238, blue: 0.3916778283, alpha: 1)
            case .Tea: return #colorLiteral(red: 0.3411764801, green: 0.7533186037, blue: 0.1686274558, alpha: 1)
            case .ColdDrink: return #colorLiteral(red: 0.4745098054, green: 0.9017959613, blue: 0.9764705896, alpha: 1)
            case .Cake: return #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
            case .Desert: return #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)
            case .Others: return #colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1)
            case .HotPot: return #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
            }
        }
        
//        var description: String {
//            switch self {
//            case .Chinese: return
//            case .Western: return
//            case .Streak: return
//            case .Japanese: return
//            case .Korean: return
//            case .FastFood: return
//            case .Leisure: return
//            case .Cafe: return
//            case .Tea: return
//            case .ColdDrink: return
//            case .Cake: return
//            case .Desert: return
//            case .Others: return
//            case .HotPot: return
//            }
//        }
        
        init(with typeStrings: String) {
            for typeString in typeStrings.split(separator: "|") {
                let types = typeString.split(separator: ";")
                if types.count <= 1 || types[0] != "餐饮服务" {
                    self = .Others
                    continue
                } else if types[1] == "中餐厅" {
                    if types.count >= 2 && types[2] == "火锅店" {
                        self = .HotPot
                    } else {
                        self = .Chinese
                    }
                } else if types[1] == "外国餐厅" {
                    if types.count >= 2 && types[2] == "日本料理" {
                        self = .Japanese
                    } else if types.count >= 2 && types[2] == "韩国料理" {
                        self = .Korean
                    } else if types.count >= 2 && types[2] == "牛扒店(扒房)" {
                        self = .Steak
                    } else {
                        self = .Western
                    }
                } else if types[1] == "快餐厅" {
                    self = .FastFood
                } else if types[1] == "休闲餐饮场所" {
                    self = .Leisure
                } else if types[1] == "咖啡厅" {
                    self = .Cafe
                } else if types[1] == "茶艺馆" {
                    self = .Tea
                } else if types[1] == "冷饮店" {
                    self = .ColdDrink
                } else if types[1] == "糕饼店" {
                    self = .Cake
                } else if types[1] == "甜品店" {
                    self = .Desert
                }else {
                    self = .Others
                }
                return 
            }
            self = .Others
        }
    }
}
