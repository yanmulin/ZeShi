//
//  Utils.swift
//  What2Eat
//
//  Created by 颜木林 on 2019/7/13.
//  Copyright © 2019 yanmulin. All rights reserved.
//

import Foundation

extension CGPoint {
    func offset(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
    
    static func ==(_ lhs: CGPoint, _ rhs: CGPoint) -> Bool {
        return lhs.x - rhs.x < 1e-6 && lhs.y - rhs.y < 1e-6
    }
}

extension CGSize {
    func offset(_ dw: CGFloat, _ dh: CGFloat) -> CGSize {
        return CGSize(width: self.width+dw, height: self.height+dh)
    }
}

extension CGRect {
    var center: CGPoint {
        return self.origin.offset(self.width / 2, self.height / 2)
    }
}
