//
//  FSUIViewExtension.swift
//  SwiftDemo
//
//  Created by iOSgo on 2018/5/16.
//  Copyright © 2018年 chen cx. All rights reserved.
//

import Foundation
import UIKit

let FSScreenBounds = UIScreen.main.bounds
let FSScreenSize = UIScreen.main.bounds.size
let FSScreenWidth = UIScreen.main.bounds.size.width
let FSScreenHeight = UIScreen.main.bounds.size.height
let fs_autoSizeScaleX = UIScreen.main.bounds.size.width / 375
let fs_autoSizeScaleY = UIScreen.main.bounds.size.height / 667
let FSKeyWindow = UIApplication.shared.windows.first


//动画类型
enum FSAnimateType: UInt {
    case Bigger = 1 //弹性动画放大
    case Smaller = 2 //缩小的弹性动画
}


extension UIView {

    // MARK: - 计算frame
    var fs_height: CGFloat {
        set {
            var newFrame = self.frame
            newFrame.size.height = fs_height
            self.frame = newFrame
        }get {
            return self.frame.size.height
        }
    }
    
    var fs_width: CGFloat {
        set {
            var newFrame = self.frame
            newFrame.size.width = fs_width
            self.frame = newFrame
        }get {
            return self.frame.size.width
        }
    }
    
    
    var fs_y: CGFloat {
        set {
            var newFrame = self.frame
            newFrame.origin.y = fs_y
            self.frame = newFrame
        }get {
            return self.frame.origin.y
        }
    }
    
    var fs_x: CGFloat {
        set {
            var newFrame = self.frame
            newFrame.origin.x = fs_x
            self.frame = newFrame
        }get {
            return self.frame.origin.x
        }
    }

    var fs_centerX: CGFloat {
        set {
            var newPoint = self.center
            newPoint.x = fs_centerX
            self.center = newPoint
        }get {
            return self.center.x
        }
    }
    
    var fs_centerY: CGFloat {
        set {
            var newPoint = self.center
            newPoint.y = fs_centerY
            self.center = newPoint
        }get {
            return self.center.y
        }
    }
    
    
    struct AssociateKey {
        static var RedTipViewKey: UInt = 0
    }
    /// 添加红点属性
    var redTipView: UILabel? {
        set {
            objc_setAssociatedObject(self, &AssociateKey.RedTipViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }get {
            return objc_getAssociatedObject(self, &AssociateKey.RedTipViewKey) as? UILabel
        }
    }
    
    /// 显示一个5*5点的红色提醒圆点
    ///
    /// - Parameters:
    ///   - redX: x坐标
    ///   - redY: y坐标
    func fs_showRedTipViewInRedX(_ redX: CGFloat, redY: CGFloat) {
        fs_showRedTipViewInRedX(redX, redY: redY, redTipViewWidth: 5)
    }
    
    /// 在view上面绘制一个指定width宽度的 指定颜色的提醒圆点
    ///
    /// - Parameters:
    ///   - redX: x坐标
    ///   - redY: y坐标
    ///   - width: 圆点的直径
    func fs_showRedTipViewInRedX(_ redX: CGFloat, redY: CGFloat, redTipViewWidth width: CGFloat) {
        fs_showRedTipViewInRedX(redX, redY: redY, redTipViewWidth: width, backgroundColor: UIColor.red)
    }
    
    /// 在view上面绘制一个指定width宽度的 指定颜色的提醒圆点
    ///
    /// - Parameters:
    ///   - redX: x坐标
    ///   - redY: y坐标
    ///   - width: 圆点的直径
    ///   - backgroundColor: 圆点的颜色
    func fs_showRedTipViewInRedX(_ redX: CGFloat, redY: CGFloat, redTipViewWidth width: CGFloat, backgroundColor: UIColor) {
        if redTipView == nil {
            redTipView = UILabel()
            redTipView?.backgroundColor = backgroundColor
            redTipView?.fs_width = width
            redTipView?.fs_height = width
            redTipView?.layer.cornerRadius = (redTipView?.fs_height)! * 0.5
            redTipView?.layer.masksToBounds = true
            insertSubview(redTipView!, at: subviews.count)
        }
        bringSubviewToFront(redTipView!)
        redTipView?.fs_x = redX
        redTipView?.fs_y = redY
        redTipView?.isHidden = false
    }
    
    
    /// 显示一个5*5点的红色提醒圆点
    ///
    /// - Parameters:
    ///   - redX: x坐标
    ///   - redY: y坐标
    ///   - numberCount: 展示的数字
    func fs_showRedTipViewWithNumberCountInRedX(_ redX: CGFloat, redY: CGFloat, numberCount: NSInteger) {
        if redTipView == nil {
            redTipView = UILabel()
            redTipView?.backgroundColor = UIColor.red
        }
        redTipView?.fs_x = redX
        redTipView?.fs_y = redY
        redTipView?.text = String(numberCount)
        redTipView?.textAlignment = .center
        redTipView?.textColor = UIColor.white
        redTipView?.font = UIFont.systemFont(ofSize: 13)
        redTipView?.sizeToFit()
        redTipView?.fs_width += 8.5
        redTipView?.layer.cornerRadius = (redTipView?.fs_height)! * 0.5
        insertSubview(redTipView!, at: subviews.count)
        redTipView?.isHidden = false
    }
    
    /// 隐藏红色提醒圆点
    func fs_hideRedTipView() {
        redTipView?.isHidden = true
    }
    
    /// 判断是否在窗口上面
    func fs_isShowingOnKeyWindow() -> Bool {
        /// 主窗口
        let keyWindow = FSKeyWindow
        
        // 以主窗口左上角为坐标原点, 计算self的矩形框
        let newFrame = keyWindow?.convert(self.frame, from: superview)
        let winBounds = keyWindow?.bounds
        
        // 主窗口的bounds 和 self的矩形框 是否有重叠
        let intersects = newFrame?.intersects(winBounds!)
        
        return !self.isHidden && self.alpha > 0.01 && self.window == keyWindow && intersects!
    }
    
    static func fs_ViewFromXib() -> UIView {
        return Bundle.main.loadNibNamed(NSStringFromClass(self), owner: nil, options: nil)?.last as! UIView
    }
    
    
    
    /// 对指定的layer进行弹性动画
    ///
    /// - Parameters:
    ///   - layer: 进行动画的图层
    ///   - type: 动画类型
    static func fs_showOscillatoryAnimationWithLayer(_ layer: CALayer, type: FSAnimateType) {
        let animationScale1: NSNumber = type == .Bigger ? 1.15 : 0.5
        let animationScale2: NSNumber = type == .Bigger ? 0.92 : 1.15
        
        UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState,.curveEaseInOut], animations: {
            layer.setValue(animationScale1, forKeyPath: "transform.scale")
        }) { (finished) in
            UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState,.curveEaseInOut], animations: {
                layer.setValue(animationScale2, forKeyPath: "transform.scale")
            }, completion: { (finished) in
                UIView.animate(withDuration: 0.1, delay: 0, options: [.beginFromCurrentState,.curveEaseInOut], animations: {
                    layer.setValue(NSNumber(value:0.1), forKeyPath: "transform.scale")
                }, completion: nil)
            })
        }
    }
    
    
    /// 给视图添加虚线边框
    ///
    /// - Parameters:
    ///   - lindWidth: 线宽
    ///   - lineMargin: 每条虚线之间的间距
    ///   - lineLength: 每条虚线的长度
    ///   - lineColor: 每条虚线的颜色
    func fs_addDottedLineBorderWithLineWidth(_ lineWidth: CGFloat, lineMargin: Float, lineLength: Float, lineColor: UIColor) {
        let border = CAShapeLayer()
        
        border.strokeColor = lineColor.cgColor
        
        border.fillColor = nil
        
        border.path = UIBezierPath(rect: self.bounds).cgPath
        
        border.frame = self.bounds
        
        border.lineWidth = lineWidth
        
        border.lineCap = CAShapeLayerLineCap(rawValue: "round")
        
        border.lineDashPattern = [NSNumber(value:lineLength), NSNumber(value:lineMargin)]
        
        layer.addSublayer(border)
    }
    
}
