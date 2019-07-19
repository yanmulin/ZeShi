//
//  Utils.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/13.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import Foundation

extension CGPoint {
    func offset(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
    
    static func ==(_ lhs: CGPoint, _ rhs: CGPoint) -> Bool {
        return lhs.x - rhs.x < 1e-6 && lhs.y - rhs.y < 1e-6
    }
}

extension CGSize {
    func offset(dw: CGFloat, dh: CGFloat) -> CGSize {
        return CGSize(width: self.width+dw, height: self.height+dh)
    }
}

extension CGRect {
    var center: CGPoint {
        return self.origin.offset(dx: self.width / 2, dy: self.height / 2)
    }
    
    var leftBottom: CGPoint {
        return self.origin.offset(dx: 0, dy: self.height)
    }
    
    var rightBottom: CGPoint {
        return self.origin.offset(dx: self.width, dy: self.height)
    }
}
