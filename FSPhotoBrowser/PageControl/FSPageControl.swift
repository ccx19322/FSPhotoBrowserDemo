//
//  FSPageControl.swift
//  SwiftDemo
//
//  Created by iOSgo on 2018/5/15.
//  Copyright © 2018年 chen cx. All rights reserved.
//

import UIKit

@objc protocol FSPageControlDelegate: NSObjectProtocol {
    @objc optional
    func FSPageControl(_ pageControl: FSPageControl, didSelectPageAtIndex index: NSInteger)
}

class FSPageControl: UIControl {

    
    /// Dot view customization properties
    
    /// The Class of your custom UIView, make sure to respect the TAAbstractDotView class.
    open var dotViewClass: AnyClass? = FSAnimateDotView.self {
        didSet {
            self.dotSize = CGSize.zero
            self.resetDotViews()
        }
    }
    
    /// UIImage to represent a dot.
    open var dotImage: UIImage? {
        didSet {
            self.resetDotViews()
            self.dotViewClass = nil
        }
    }
    
    /// UIImage to represent current page dot.
    open var currentDotImage: UIImage? {
        didSet {
            self.resetDotViews()
            self.dotViewClass = nil
        }
    }
    
    /// Dot size for dot views. Default is 8 by 8.
    open var dotSize: CGSize
    {
        set {
            self.dotSize = newValue
        }
        get {
            let size: CGSize
            if let image = self.dotImage {
                size = image.size
            } else if self.dotViewClass != nil {
                size = CGSize(width: 8, height: 8)
            } else {
                size = CGSize(width: 8, height: 8)
            }
            return size
        }
        
    }
    
    /// <#Description#>
    open var dotColor: UIColor?
    
    /// Spacing between two dot views. Default is 8.
    open var spacingBetweenDots: NSInteger = 8 {
        didSet {
            self.resetDotViews()
        }
    }
    
    /// Delegate for TAPageControl
    open weak var delegate: FSPageControlDelegate?
    
    /// Number of pages for control. Default is 0.
    open var numberOfPages: NSInteger = 0 {
        didSet {
            self.resetDotViews()
        }
    }
    
    /// Current page on which control is active. Default is 0.
    open var currentPage: NSInteger = 0 {
        didSet {
            // Pre set
            self.changeActivity(false, atIndex: currentPage)
            // Post set
            self.changeActivity(true, atIndex: currentPage)
        }
    }
    
    /// Hide the control if there is only one page. Default is false.
    open var hidesForSinglePage: Bool = false
    
    /// Let the control know if should grow bigger by keeping center, or just get longer (right side expanding). By default true.
    open var shouldResizeFromCenter: Bool = true
    
    /// Return the minimum size required to display control properly for the given page count.
    ///
    /// - Parameter pageCount: Number of dots that will require display
    /// - Returns: The CGSize being the minimum size required.
    open func sizeForNumberOfPages(pageCount: NSInteger) -> CGSize {
        return CGSize(width: self.dotSize.width+CGFloat(self.spacingBetweenDots*pageCount)-CGFloat(self.spacingBetweenDots), height: self.dotSize.height)
    }
    
    
    //// private
    private var dots = [Any]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchesSet = touches as NSSet
        let touch = touchesSet.anyObject() as! UITouch
        if (touch.view as? UIPageControl) == nil {
            let idx = (dots as NSArray).index(of: touch.view!)
            if self.delegate != nil && (delegate?.responds(to: #selector(delegate?.FSPageControl(_:didSelectPageAtIndex:))))! {
                self.delegate?.FSPageControl!(self, didSelectPageAtIndex: idx)
            }
        }
    }
    
    /// MARK: - Layout
    override func sizeToFit() {
        updateFrame(true)
    }
    
    /// Will update dots display and frame. Reuse existing views or instantiate one if required. Update their position in case frame changed.
    private func updateDots() {
        if self.numberOfPages == 0 {
            return
        }
        for i in 0...self.numberOfPages-1 {
            let dot: UIView
            if i < self.dots.count {
                dot = self.dots[i] as! UIView
            } else {
                dot = self.generateDotView()
            }
            self.updateDotFrame(dot: dot, atIndex: i)
            
        }
        
        self.changeActivity(true, atIndex: self.currentPage)
        self.hideForSinglePage()
    }

    
    /// Update frame control to fit current number of pages. It will apply required size if authorize and required.
    ///
    /// - Parameter overrideExistingFrame: BOOL to allow frame to be overriden. Meaning the required size will be apply no mattter what.
    private func updateFrame(_ overrideExistingFrame: Bool) {
        let center = self.center
        let requireSize = self.sizeForNumberOfPages(pageCount: self.numberOfPages)
        /// We apply requiredSize only if authorize to and necessary
        if overrideExistingFrame || ((self.frame.size.width < requireSize.width || self.frame.size.height < requireSize.height) && !overrideExistingFrame) {
            self.frame = CGRect.init(x: self.frame.origin.x, y: self.frame.origin.y, width: requireSize.width, height: requireSize.height)
            if self.shouldResizeFromCenter {
                self.center = center
            }
        }
    }
    
    
    /// Update the frame of a specific dot at a specific index
    ///
    /// - Parameters:
    ///   - dot: Dot view
    ///   - index: Page index of dot
    private func updateDotFrame(dot: UIView, atIndex index: NSInteger) {
        /// Dots are always centered within view
        let x = (self.dotSize.width + CGFloat(self.spacingBetweenDots)) * CGFloat(index) + self.frame.size.width - self.sizeForNumberOfPages(pageCount: self.numberOfPages).width/2
        let y = (self.frame.size.height - self.dotSize.height)/2
        dot.frame = CGRect.init(x: x, y: y, width: self.dotSize.width, height: self.dotSize.height)
    }
    
    
    /// MARK: - Utils
    
    /// Generate a dot view and add it to the collection
    ///
    /// - Returns: The UIView object representing a dot
    private func generateDotView() -> UIView {
        let dotView: UIView
        if let classType = self.dotViewClass as? FSAnimateDotView.Type  {
            dotView = classType.init()
            dotView.frame = CGRect(x: 0, y: 0, width: self.dotSize.width, height: self.dotSize.height)
            if (dotView as? FSAnimateDotView) != nil && self.dotColor != nil {
                (dotView as! FSAnimateDotView).dotColor = self.dotColor
            }
        } else {
            dotView = UIImageView(image: self.dotImage)
            dotView.frame = CGRect(x: 0, y: 0, width: self.dotSize.width, height: self.dotSize.height)
        }
        
        self.addSubview(dotView)
        self.dots.append(dotView)
        
        dotView.isUserInteractionEnabled = true
        return dotView
    }
    
    
    /// Change activity state of a dot view. Current/not currrent.
    ///
    /// - Parameters:
    ///   - active: Active state to apply
    ///   - index: Index of dot for state update
    private func changeActivity(_ active: Bool, atIndex index: NSInteger) {
        if self.dotViewClass != nil {
            let abstractDotView = self.dots[index] as! FSAbstractDotView
            abstractDotView.changeActivityState(active)
        } else if (self.dotImage != nil && self.currentDotImage != nil) {
            let dotView = self.dots[index] as! UIImageView
            dotView.image = active ? self.currentDotImage : self.dotImage
        }
    }
    
    private func resetDotViews() {
        for dotView in self.dots {
            if let dv = dotView as? UIView {
                dv.removeFromSuperview()
            }
        }
        
        self.dots.removeAll()
        self.updateDots()
    }
    
    private func hideForSinglePage() {
        if self.dots.count == 1 && self.hidesForSinglePage {
            self.isHidden = true
        } else {
            self.isHidden = false
        }
    }
    
}


