//
//  FSProgressView.swift
//  SwiftDemo
//
//  Created by iOSgo on 2018/5/16.
//  Copyright © 2018年 chen cx. All rights reserved.
//

import UIKit

class FSProgressView: UIView {

    open var progress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
            if progress >= 1 {
                removeFromSuperview()
            }
        }
    }
    open var mode: FSProgressViewMode!

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = FSProgressViewBackgroundColor
        layer.cornerRadius = 5
        clipsToBounds = true
        mode = FSProgressViewProgressMode
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        
        let xCenter = rect.size.width * 0.5
        let yCenter = rect.size.height * 0.5
        backgroundColor?.setFill()
        FSProgressViewStrokeColor.setStroke()
        
        // Double.pi == M_PI
        switch mode {
        case .PieDiagram?:
            let radius = min(rect.size.width*0.5, rect.size.height*0.5)-CGFloat(FSProgressViewItemMargin)
            
            let w = radius * 2 + CGFloat(FSProgressViewItemMargin)
            let h = w
            let x = (rect.size.width - w) * 0.5
            let y = (rect.size.height - h) * 0.5
            ctx?.addEllipse(in: CGRect(x: x, y: y, width: w, height: h))
            ctx?.setLineWidth(CGFloat(Double(FSProgressViewLoopDiagramLineWidth)*0.5))
            ctx?.strokePath()
            
            FSProgressViewStrokeColor.setFill()
            ctx?.move(to: CGPoint(x: xCenter, y: yCenter))
            ctx?.addLine(to: CGPoint(x: xCenter, y: 0))
            let to = -Double.pi * 0.5 + Double( self.progress) * Double.pi * 2.0 + 0.001 //初始值
            ctx?.addArc(tangent1End: CGPoint.init(x: xCenter, y: yCenter), tangent2End: CGPoint.init(x: -Double.pi*0.5, y: to), radius: radius)
            ctx?.closePath()
            ctx?.fillPath()
            break
            
        default:
            ctx?.setLineWidth(CGFloat(FSProgressViewLoopDiagramLineWidth))
            ctx?.setLineCap(.round)
            FSProgressViewStrokeColor.setStroke()
            let to = -Double.pi * 0.5 + Double( self.progress) * Double.pi * 2.0 + 0.05 //初始值
            let radius = min(rect.size.width, rect.size.height)*0.5-CGFloat(FSProgressViewItemMargin)
            ctx?.addArc(tangent1End: CGPoint.init(x: xCenter, y: yCenter), tangent2End: CGPoint.init(x: -Double.pi*0.5, y: to), radius: radius)
            ctx?.strokePath()
            break
            
        }
    }
    
}
