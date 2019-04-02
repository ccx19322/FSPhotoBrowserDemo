//
//  FSZoomingScrollView.swift
//  SwiftDemo
//
//  Created by iOSgo on 2018/5/16.
//  Copyright © 2018年 chen cx. All rights reserved.
//

import UIKit
import Kingfisher

@objc protocol FSZoomingScrollViewDelegate: NSObjectProtocol {
    
    /// 单击图像时调用
    ///
    /// - Parameters:
    ///   - zoomingScrollView: 图片缩放视图
    ///   - singleTap: 用户单击手势
    func zoomingScrollView(_ zoomingScrollView: FSZoomingScrollView, singleTapDetected singleTap: UITapGestureRecognizer)
    
    /// 图片加载进度
    ///
    /// - Parameters:
    ///   - zoomingScrollView: 图片缩放视图
    ///   - progress: 加载进度 , 0 - 1.0
    @objc optional func zoomingScrollView(_ zoomingScrollView: FSZoomingScrollView, imageLoadProgress progress: CGFloat)
}

class FSZoomingScrollView: UIView {

    /// zoomingScrollViewdelegate
    open weak var zoomingScrollViewdelegate: FSZoomingScrollViewDelegate?
    /// 图片加载进度
    open var progress: CGFloat! {
        didSet {
            progressView.progress = progress
            
            if self.zoomingScrollViewdelegate != nil && (self.zoomingScrollViewdelegate?.responds(to: #selector(self.zoomingScrollViewdelegate?.zoomingScrollView(_:imageLoadProgress:))))! {
                self.zoomingScrollViewdelegate?.zoomingScrollView!(self, imageLoadProgress: progress)
            }
        }
    }
    
    /// 展示的图片
    open var currentImage: UIImage {
        get {
            return self.photoImageView.image!
        }
    }
    /// 展示图片的UIImageView视图  ,  回缩的动画用
    open var imageView: UIImageView {
        get {
            return self.photoImageView
        }
    }
    open lazy var scrollView: UIScrollView = {
        let scrollV = UIScrollView()
        scrollV.addSubview(photoImageView)
        scrollV.delegate = self
        scrollV.clipsToBounds = true
        scrollV.showsVerticalScrollIndicator = false
        scrollV.showsHorizontalScrollIndicator = false
        addSubview(scrollV)
        return scrollV
    }()
    
    
    /// 显示图片
    ///
    /// - Parameters:
    ///   - url: 图片的高清大图链接
    ///   - placeholder: 占位的缩略图 / 或者是高清大图都可以
    open func setShowHighQualityImageWithURL(_ url: URL?, placeholderImage placeholder: UIImage) {
        if url == nil {
            setShowImage(placeholder)
            return
        }
        
        let cacheImage = KingfisherManager.shared.cache.retrieveImageInDiskCache(forKey: (url?.absoluteString)!)
        if cacheImage != nil {
            setShowImage(cacheImage!)
            return
        }
        
        photoImageView.image = placeholder
        setMaxAndMinZoomScales()
        
        addSubview(progressView)
        progressView.mode = FSProgressViewProgressMode
        imageURL = url
        
        photoImageView.kf.setImage(with: url, placeholder: placeholder, options: nil, progressBlock: { (receivedSize, expectedSize) in
            self.progress = CGFloat(receivedSize/expectedSize)
        }) { (image, error, cacheType, imageURL) in
            self.progressView.removeFromSuperview()
            if (error != nil) {
                self.setMaxAndMinZoomScales()
                self.addSubview(self.stateLabel)
            } else {
                self.stateLabel.removeFromSuperview()
                UIView.animate(withDuration: 0.25, animations: {
                    self.setShowImage(image!)
                    self.photoImageView.setNeedsDisplay()
                    self.setMaxAndMinZoomScales()
                })
            }
        }
    }
    
    
    /// 显示图片
    ///
    /// - Parameter image: 图片
    open func setShowImage(_ image: UIImage) {
        self.photoImageView.image = image
        setMaxAndMinZoomScales()
        setNeedsLayout()
        progress = 1.0
        hasLoadedImage = true
    }
    
    /// 根据图片和屏幕比例关系,调整最大和最小伸缩比例
    open func setMaxAndMinZoomScales() {
        let image = photoImageView.image
        if  image == nil || image?.size.height == 0 {
            return
        }
        let imageWidthHeightRatio = (image?.size.width)!/(image?.size.height)!
        
        let width = self.fs_width
        let height = self.fs_width/imageWidthHeightRatio
        let x = 0
        var y: CGFloat
        if height > FSScreenHeight {
            y = 0
            scrollView.isScrollEnabled = true
        } else {
            y = (FSScreenHeight - height) * 0.5
            scrollView.isScrollEnabled = false
        }
        photoImageView.frame = CGRect(x: CGFloat(x), y: y, width: width, height: height)
        scrollView.maximumZoomScale = max(FSScreenHeight/photoImageView.fs_height, 3.0)
        scrollView.minimumZoomScale = 1.0
        scrollView.zoomScale = 1.0
        scrollView.contentSize = CGSize.init(width: photoImageView.fs_width, height: max(photoImageView.fs_height, FSScreenHeight))
    }
    
    /// 重用，清理资源
    open func prepareForReuse() {
        setMaxAndMinZoomScales()
        progress = 0
        photoImageView.image = nil
        hasLoadedImage = false
        stateLabel.removeFromSuperview()
        progressView.removeFromSuperview()
    }
    
    ///// private
    lazy private var photoImageView: UIImageView = {
        let photoIMGV = UIImageView()
        photoIMGV.backgroundColor = UIColor.red
        return photoIMGV
    }()
    lazy private var progressView: FSProgressView = {
        let progressV = FSProgressView()
        return progressV
    }()
    lazy private var stateLabel: UILabel = {
       let label = UILabel()
        label.text = FSPhotoBrowserLoadNetworkImageFail
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.8)
        label.layer.cornerRadius = 5
        label.clipsToBounds = true
        label.textAlignment = .center
        return label
    }()
    private var hasLoadedImage: Bool!
    private var imageURL: URL!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let singleTapBackgroundView = UITapGestureRecognizer(target: self, action: #selector(singleTapBackgroundView(_:)))
        let doubleTapBackgroundView = UITapGestureRecognizer(target: self, action: #selector(doubleTapBackgroundView(_:)))
        doubleTapBackgroundView.numberOfTapsRequired = 2
        singleTapBackgroundView.require(toFail: doubleTapBackgroundView)
        self.addGestureRecognizer(singleTapBackgroundView)
        self.addGestureRecognizer(doubleTapBackgroundView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    @objc private func singleTapBackgroundView(_ singleTap: UITapGestureRecognizer) {
        if zoomingScrollViewdelegate != nil {
            zoomingScrollViewdelegate?.zoomingScrollView(self, singleTapDetected: singleTap)
        }
    }
    
    @objc private func doubleTapBackgroundView(_ doubleTap: UITapGestureRecognizer) {
        if !hasLoadedImage {
            return
        }
        scrollView.isUserInteractionEnabled = false
        
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let point = doubleTap.location(in: doubleTap.view)
            var touchX = point.x
            var touchY = point.y
            touchX *= 1/scrollView.zoomScale
            touchY *= 1/scrollView.zoomScale
            touchX += scrollView.contentOffset.x
            touchY += scrollView.contentOffset.y
            let zoomRect = zoomRectForScale(scrollView.maximumZoomScale, withCenter: CGPoint(x: touchX, y: touchY))
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    private func resetZoomScale() {
        scrollView.maximumZoomScale = 1.0
        scrollView.minimumZoomScale = 1.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        stateLabel.frame = CGRect(x: 0, y: 0, width: 160, height: 30)
        stateLabel.center = CGPoint(x: self.bounds.size.width * 0.5, y: self.bounds.size.height * 0.5)
        
        progressView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        progressView.center = CGPoint(x: self.fs_width * 0.5, y: self.fs_height * 0.5)
        scrollView.frame = self.bounds
        
        setMaxAndMinZoomScales()
    }
    
}

// MARK: - UIScrollViewDelegate
extension FSZoomingScrollView: UIScrollViewDelegate {
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        photoImageView.center = centerOfScrollViewContent(scrollView)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.photoImageView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.scrollView.isScrollEnabled = true
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.scrollView.isUserInteractionEnabled = true
    }
    
    
}


// MARK: - private method - 手势处理,缩放图片
extension FSZoomingScrollView {
    
    func centerOfScrollViewContent(_ scrollView: UIScrollView) -> CGPoint {
        let offsetX = scrollView.bounds.size.width > scrollView.contentSize.width ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0
        let offsetY = scrollView.bounds.size.height > scrollView.contentSize.height ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0
        let actualCenter = CGPoint(x: scrollView.contentSize.width*0.5 + offsetX, y: scrollView.contentSize.height*0.5 + offsetY)
        return actualCenter
    }
    
    func zoomRectForScale(_ scale: CGFloat, withCenter center: CGPoint) -> CGRect {
        let height = self.frame.size.height / scale
        let width = self.frame.size.width / scale
        let x = center.x - width * 0.5
        let y = center.y - height * 0.5
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    
    
    
    
    
    
    
}
