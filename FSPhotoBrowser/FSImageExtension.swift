//
//  FSImageExtension.swift
//  SwiftDemo
//
//  Created by iOSgo on 2018/5/16.
//  Copyright © 2018年 chen cx. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    /// 返回一张指定size的指定颜色的纯色图片
    static func FS_imageWithColor(_ color: UIColor, size: CGSize? = nil) -> UIImage {
        var sizeRc: CGSize
        if size == nil {
            sizeRc = CGSize(width: 3, height: 3)
        } else {
            sizeRc = size!
        }
        let rect = CGRect(x: 0, y: 0, width: sizeRc.width, height: sizeRc.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
}

