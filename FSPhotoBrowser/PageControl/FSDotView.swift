//
//  FSAbstractDotView.swift
//  SwiftDemo
//
//  Created by iOSgo on 2018/5/15.
//  Copyright © 2018年 chen cx. All rights reserved.
//

import UIKit


/// FSAbstractDotView
class FSAbstractDotView: UIView {

    /// A method call let view know which state appearance it should take. Active meaning it's current page. Inactive not the current page.
    ///
    /// - Parameter active: to tell if view is active or not
    func changeActivityState(_ active: Bool) {
        _=NSException(name: NSExceptionName.internalInconsistencyException,
                    reason: String(format: "You must override %@ in %@", NSStringFromSelector(#function),self.classForCoder as! CVarArg),
                    userInfo: nil)
    }
    
}


/// FSAnimateDotView
class FSAnimateDotView: FSAbstractDotView {
    
    var dotColor: UIColor!
    let kAnimateDuration = 1
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialization()
    }
    
    private func initialization() {
        dotColor = UIColor.white
        self.backgroundColor = UIColor.clear
        self.layer.cornerRadius = self.frame.size.width/2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 2
    }
    
    override func changeActivityState(_ active: Bool) {
        if active {
            animateToActiveState()
        } else {
            animateToDeactiveState()
        }
    }
    
  private  func animateToActiveState() {
        UIView.animate(withDuration: TimeInterval(kAnimateDuration), delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: -20, options: .curveLinear, animations: {
            self.backgroundColor = self.dotColor
            self.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        }, completion: nil)
    }
    
    private func animateToDeactiveState() {
        UIView.animate(withDuration: TimeInterval(kAnimateDuration), delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: -20, options: .curveLinear, animations: {
            self.backgroundColor = UIColor.clear
            self.transform = CGAffineTransform.identity
        }, completion: nil)
    }
}


/// FSDotView
class FSDotView: FSAbstractDotView {
    
    var dotColor: UIColor!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialization()
    }
    
    private func initialization() {
        dotColor = UIColor.white
        self.backgroundColor = UIColor.clear
        self.layer.cornerRadius = self.frame.size.width/2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 2
    }
    
    override func changeActivityState(_ active: Bool) {
        if active {
            self.backgroundColor = UIColor.white
        } else {
            self.backgroundColor = UIColor.clear
        }
    }
    
    
}
