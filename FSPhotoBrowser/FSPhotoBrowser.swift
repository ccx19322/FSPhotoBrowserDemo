//
//  FSPhotoBrowser.swift
//  SwiftDemo
//
//  Created by iOSgo on 2018/5/16.
//  Copyright © 2018年 chen cx. All rights reserved.
//

import UIKit
import AssetsLibrary

@objc protocol FSPhotoBrowserDelegate: NSObjectProtocol {
    /// 点击底部actionSheet回调,对于图片添加了长按手势的底部功能组件
    ///
    /// - Parameters:
    ///   - browser: 图片浏览器
    ///   - actionSheetindex: 点击的actionSheet索引
    ///   - currentImageIndex: 当前展示的图片索引
    @objc optional func photoBrowser(_ browser: FSPhotoBrowser, clickActionSheetIndex actionSheetindex: NSInteger, currentImageIndex: NSInteger)
    
}

@objc protocol FSPhotoBrowserDatasource: NSObjectProtocol {
    
    /// 返回这个位置的占位图片 , 也可以是原图(如果不实现此方法,会默认使用placeholderImage)
    ///
    /// - Parameters:
    ///   - browser: 浏览器
    ///   - index: 位置索引
    /// - Returns: 占位图片
    @objc optional func photoBrowser(_ browser: FSPhotoBrowser, placeholderImageForIndex index: NSInteger) -> UIImage
    
    
    /// 返回指定位置的高清图片URL
    ///
    /// - Parameters:
    ///   - browser: 浏览器
    ///   - index: 位置索引
    /// - Returns: 返回高清大图索引
    @objc optional func photoBrowser(_ browser: FSPhotoBrowser, highQualityImageURLForIndex index: NSInteger) -> URL
    
    /// 返回指定位置的ALAsset对象,从其中获取图片
    ///
    /// - Parameters:
    ///   - browser: 浏览器
    ///   - index: 位置索引
    /// - Returns: 返回高清大图索引
    @objc optional func photoBrowser(_ browser: FSPhotoBrowser, assetForIndex index: NSInteger) -> ALAsset
    
    
    /// 返回指定位置图片的UIImageView,用于做图片浏览器弹出放大和消失回缩动画等
    ///如果没有实现这个方法,没有回缩动画,如果传过来的view不正确,可能会影响回缩动画
    /// - Parameters:
    ///   - browser: 浏览器
    ///   - index: 位置索引
    /// - Returns: 展示图片的UIImageView
    @objc optional func photoBrowser(_ browser: FSPhotoBrowser, sourceImageViewForIndex index: NSInteger) -> UIImageView
}

class FSPhotoBrowser: UIView {

    /// 用户点击的图片视图,用于做图片浏览器弹出的放大动画,不给次属性赋值会通过代理方法photoBrowser: sourceImageViewForIndex:尝试获取,如果还是获取不到则没有弹出放大动画
    open var sourceImageView: UIImageView?
    /// 当前显示的图片位置索引 , 默认是0
    open var currentImageIndex: NSInteger = 0
    /// 浏览的图片数量,大于0
    open var imageCount: NSInteger = 0
    /// 图片数组，url链接
    open var images: [Any]! {
        didSet {
            imageCount = images.count
        }
    }
    /// datasource
    open var datasource: FSPhotoBrowserDatasource?
    /// delegate
    open var delegate: FSPhotoBrowserDelegate?
    /// browserStyle
    open var browserStyle: FSPhotoBrowserStyle = .PageControl {
        didSet {
            updateIndexVisible()
        }
    }
    /// 占位图片,可选(默认是一张灰色的100*100像素图片)
    /// 当没有实现数据源中placeholderImageForIndex方法时,默认会使用这个占位图片
    lazy open var placeholderImage: UIImage = {
        let image = UIImage.FS_imageWithColor(UIColor.gray, size: CGSize(width: 100, height: 100))
        return image
    }()
    
    /// MARK: - 自定义PageControl样式接口
    /// 是否在只有一张图时隐藏pagecontrol，默认为YES
    open var hidesForSinglePage: Bool = true {
        didSet {
            updateIndexVisible()
        }
    }
    /// pagecontrol 样式，默认为FSPhotoBrowserPageControlStyleClassic样式
    open var pageControlStyle: FSPhotoBrowserPageControlStyle = .Classic {
        didSet {
            setUpPageControl()
            updateIndexVisible()
        }
    }
    /// 分页控件位置 , 默认为FSPhotoBrowserPageControlAlimentCenter
    open var pageControlAliment: FSPhotoBrowserPageControlAligment = .Center {
        didSet {
            switch pageControlAliment {
            case .Left:
                pageControl.fs_x = 10
                break
            case .Right:
                pageControl.fs_x = self.fs_width - pageControl.fs_width - 10
                break
            case .Center:
                pageControl.fs_x = (self.fs_width - pageControl.fs_width) * 0.5
                break
            }
        }
    }
    /// 当前分页控件小圆标颜色
    open var currentPageDotColor: UIColor = UIColor.white {
        didSet {
            if let pageCtrl = pageControl as? FSPageControl {
                pageCtrl.dotColor = currentPageDotColor
            } else if let pageCtrl = pageControl as? UIPageControl {
                pageCtrl.currentPageIndicatorTintColor = currentPageDotColor
            }
        }
    }
    /// 其他分页控件小圆标颜色
    open var pageDotColor: UIColor = UIColor.lightGray {
        didSet {
            if let pageCtrl = pageControl as? UIPageControl {
                pageCtrl.pageIndicatorTintColor = pageDotColor
            }
        }
    }
    /// 当前分页控件小圆标图片
    open var currentPageDotImage: UIImage! {
        didSet {
            setCustomPageControlDotImage(currentPageDotImage, isCurrentPageDot: true)
        }
    }
    /// 其他分页控件小圆标图片
    open var pageDotImage: UIImage! {
        didSet {
            setCustomPageControlDotImage(pageDotImage, isCurrentPageDot: false)
        }
    }
    
    /// MARK: - FSPhotoBrowser控制接口
    
    /// 快速创建并进入图片浏览器 , 同时传入数据源对象
    ///
    /// - Parameters:
    ///   - currentImageIndex: 开始展示的图片索引
    ///   - imageCount: 图片数量
    ///   - datasource: 数据源
    /// - Returns: FSPhotoBrowser实例对象
    public static func showPhotoBrowser(currentImageIndex: NSInteger, imageCount:NSInteger, datasource: FSPhotoBrowserDatasource) -> FSPhotoBrowser {
        let browser = FSPhotoBrowser()
        browser.imageCount = imageCount
        browser.currentImageIndex = currentImageIndex
        browser.datasource = datasource
        browser.show()
        return browser
    }
    
    /// 一行代码展示 (在某些使用场景,不需要做很复杂的操作,例如不需要长按弹出actionSheet,从而不需要实现数据源方法和代理方法,那么可以选择这个方法,直接传数据源数组进来,框架内部做处理)
    ///
    /// - Parameters:
    ///   - images: 图片数据源数组(数组内部可以是UIImage/NSURL网络图片地址/ALAsset,但只能是其中一种)
    ///   - currentImageIndex: 展示第几张,从0开始
    /// - Returns: FSPhotoBrowser实例对象
    public static func showPhotoBrowser(images: [Any], currentImageIndex: NSInteger) -> FSPhotoBrowser? {
        if images.count <= 0 {
            return nil // 一行代码展示图片浏览的方法,传入的数据源为空,请检查传入数据源
        }
        for image in images {
            if (image as? UIImage) == nil && (image as? String) == nil && (image as? URL) == nil && (image as? ALAsset) == nil {
                return nil //识别到非法数据格式,请检查传入数据是否为 NSString/NSURL/ALAsset 中一种
            }
        }
        let browser = FSPhotoBrowser()
        browser.imageCount = images.count
        browser.currentImageIndex = currentImageIndex
        browser.images = images
        browser.show()
        return browser
    }
    
    /// 初始化底部ActionSheet弹框数据 , 不实现此方法,则没有类似微信那种长按手势弹框
    ///
    /// - Parameters:
    ///   - title: ActionSheet的title
    ///   - delegate: FSPhotoBrowserDelegate
    ///   - cancelButtonTitle: 取消按钮文字
    ///   - deleteButtonTitle: 删除按钮文字,如果为nil,不显示删除按钮
    ///   - otherButtonTitles: 其他按钮数组
    open func setActionSheetWithTitle(_ title: String, delegate: FSPhotoBrowserDelegate?, cancelButtonTitle: String, deleteButtonTitle: String, otherButtonTitles: [String]) {
        actionSheetTitle = title
        actionOtherButtonTitles = otherButtonTitles
        actionSheetCancelTitle = cancelButtonTitle
        actionSheetDeleteButtonTitle = deleteButtonTitle
        self.delegate = delegate
    }
    
    /// 保存当前展示的图片
    open func saveCurrentShowImage() {
        saveImage()
    }
    
    /// 进入图片浏览器
    open func show() {
        if imageCount <= 0 {
            return
        }
        if currentImageIndex >= imageCount {
            currentImageIndex = imageCount - 1
        }
        if currentImageIndex < 0 {
            currentImageIndex = 0
        }
        
        self.frame = (photoBrowserWindow?.bounds)!
        self.alpha = 0.0
        photoBrowserWindow?.rootViewController?.view.addSubview(self)
        photoBrowserWindow?.makeKeyAndVisible()
        UIApplication.shared.setStatusBarHidden(true, with: .fade)
        iniaialUI()
    }
    
    /// 退出
    open func dismiss() {
        UIApplication.shared.setStatusBarHidden(false, with: .fade)
        UIView.animate(withDuration: FSPhotoBrowserHideImageAnimationDuration, animations: {
            self.alpha = 0.0
        }) { (finished) in
            self.removeFromSuperview()
            self.photoBrowserWindow?.rootViewController = nil
            self.photoBrowserWindow = nil
        }
    }
    
    private func setCustomPageControlDotImage(_ image: UIImage?, isCurrentPageDot: Bool) {
        if image != nil || pageControl != nil {
            return
        }
        
        if let pageCtrl = pageControl as? FSPageControl {
            if isCurrentPageDot {
                pageCtrl.currentDotImage = image
            } else {
                pageCtrl.dotImage = image
            }
        } else if let pageCtrl = pageControl as? UIPageControl {
            if isCurrentPageDot {
                pageCtrl.setValue(image, forKey: "_currentPageImage")
            } else {
                pageCtrl.setValue(image, forKey: "_pageImage")
            }
        }
        
    }
    
    /// MARK: - private
    let BaseTag = 100
    lazy private var photoBrowserWindow: UIWindow? = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.windowLevel = UIWindow.Level(CGFloat(MAXFLOAT))
        //window.windowLevel = UIWindowLevelAlert //2000的优先级,这样不会遮盖UIAlertView的提示弹框
        let tempVC = UIViewController()
        tempVC.view.backgroundColor = FSPhotoBrowserBackgrounColor
        window.rootViewController = tempVC
        return window
    }()
    /// 存放所有图片的容器
    private var scrollView: UIScrollView!
    /// 保存图片的过程指示菊花
    lazy private var indicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.style = .whiteLarge
        return view
    }()
    /// 保存图片的结果指示labe
    lazy private var saveImageTipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.90)
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 17)
        return label
    }()
    /// 正在使用的FSZoomingScrollView对象集
    private var visibleZoomingScrollViews: NSMutableSet = NSMutableSet()
    /// 循环利用池中的FSZoomingScrollView对象集,用于循环利用
    private var reusableZoomingScrollViews: NSMutableSet = NSMutableSet()
    /// pageControl
    private var pageControl: UIControl!
    /// index label
    private var indexLabel: UILabel!
    /// 保存按钮
    private var saveButton: UIButton!
    /// ActionSheet的otherbuttontitles
    private var actionOtherButtonTitles: [String]!
    /// ActionSheet的title
    private var actionSheetTitle: String!
    /// actionSheet的取消按钮title
    private var actionSheetCancelTitle: String!
    /// actionSheet的高亮按钮title
    private var actionSheetDeleteButtonTitle: String!
    /// pageControl Dot Size
    private var pageControlDotSize: CGSize = CGSize(width: 10, height: 10)
  
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
    }
    
    
    private func iniaialUI() {
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.backgroundColor = UIColor.clear
        addSubview(scrollView)
        
        if currentImageIndex == 0 {
            // 如果刚进入的时候是0,不会调用scrollViewDidScroll:方法,不会展示第一张图片
            showPhotos()
        }
        
        setUpPageControl()
        
        // 添加FNPhotoBrowserStyleSimple相关控件
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 18)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.clipsToBounds = true
        indexLabel = label
        addSubview(label)
        
        let button = UIButton()
        button.setTitle("保存", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.90)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(saveImage), for: .touchUpInside)
        saveButton = button
        addSubview(button)
        
        showFirstImage()
        updateIndexContent()
        updateIndexVisible()
    }
    
    private func setUpPageControl() {
        if pageControl != nil {
            //重新加载数据时调整
            pageControl.removeFromSuperview()
            pageControl = nil
        }
        switch pageControlStyle {
        case .Animated:
            let pageCtrl = FSPageControl()
            pageCtrl.numberOfPages = imageCount
            pageCtrl.dotColor = currentPageDotColor
            pageCtrl.currentPage = currentImageIndex
            pageCtrl.isUserInteractionEnabled = false
            addSubview(pageCtrl)
            pageControl = pageCtrl
            break
        case .Classic:
            let pageCtrl = UIPageControl()
            pageCtrl.numberOfPages = imageCount
            pageCtrl.currentPageIndicatorTintColor = currentPageDotColor
            pageCtrl.pageIndicatorTintColor = pageDotColor
            pageCtrl.isUserInteractionEnabled = false
            addSubview(pageCtrl)
            pageControl = pageCtrl
        default:
            break
        }
        // 重设pagecontroldot图片
        let CurpageDotImage = currentPageDotImage
        currentPageDotImage = CurpageDotImage
        let dotImage = pageDotImage
        pageDotImage = dotImage
    }
    
    deinit {
        reusableZoomingScrollViews.removeAllObjects()
        visibleZoomingScrollViews.removeAllObjects()
    }
    
    // MARK: - layout
    
    @objc private func orientationDidChange() {
        scrollView.delegate = nil //旋转期间,禁止调用scrollView的代理事件等
        
    }
    
    private func updateFrames() {
        self.frame = UIScreen.main.bounds
        var rect = self.bounds
        rect.size.width += CGFloat(FSPhotoBrowserImageViewMargin)
        scrollView.frame = rect // frame修改的时候,也会触发scrollViewDidScroll,不是每次都触发
        scrollView.fs_x = 0
        scrollView.contentSize = CGSize(width: scrollView.fs_width * CGFloat(imageCount), height: 0)
        scrollView.contentOffset = CGPoint(x: CGFloat(currentImageIndex)*scrollView.fs_width, y: 0) //会触发scrollViewDidScroll
        scrollView.subviews.enumerated().forEach { (idx,obj) in
            if obj.tag > BaseTag {
                obj.frame = CGRect.init(x: scrollView.fs_width*CGFloat(obj.tag-BaseTag), y: 0, width: self.fs_width, height: self.fs_height)
            }
        }
        
        saveButton.frame = CGRect(x: 30, y: self.fs_height - 70, width: 50, height: 25)
        indexLabel.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        indexLabel.center = CGPoint(x: self.fs_width * 0.5, y: 35)
        indexLabel.layer.cornerRadius = indexLabel.fs_height * 0.5
        
        saveImageTipLabel.layer.cornerRadius = 5
        saveImageTipLabel.clipsToBounds = true
        saveImageTipLabel.sizeToFit()
        saveImageTipLabel.fs_height = 30
        saveImageTipLabel.fs_width += 20
        saveImageTipLabel.center = self.center
        
        indicatorView.center = self.center
        
        var size = CGSize.zero
        if let pageCtrl = pageControl as? FSPageControl {
            size = pageCtrl.sizeForNumberOfPages(pageCount: imageCount)
            // FSPageControl 本身设计的缺陷,如果FSPageControl在设置颜色等属性以后再给frame,里面的圆点位置可能不正确 , 但是调用sizeToFit 又会改变FSPageControl的显隐状态,所以还需要
            let hidden = pageCtrl.isHidden
            pageCtrl.sizeToFit()
            pageCtrl.isHidden = hidden
        } else {
            size = CGSize(width: CGFloat(imageCount)*pageControlDotSize.width*1.2, height: pageControlDotSize.height)
        }
        var x: CGFloat
        switch pageControlAliment {
        case .Center:
            x = (self.fs_width - size.width) * 0.5
            break
        case .Left:
            x = 10
            break
        case .Right:
            x = self.fs_width-size.width-10
            break
        }
        let y = self.fs_height - size.height - 10
        pageControl.frame = CGRect.init(x: x, y: y, width: size.width, height: size.height)
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateFrames()
    }
    
    // MARK: - private -- 长按图片相关
    @objc private func longPress(_ longPressGesture: UILongPressGestureRecognizer) {
        let currentZoomingScrollView = zoomingScrollViewAtIndex(currentImageIndex)
        if longPressGesture.state == .began {
            if currentZoomingScrollView.progress < 1.0 {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.10, execute: {
                    self.longPress(longPressGesture)
                })
                return
            }
            
            if actionOtherButtonTitles.count <= 0 && actionSheetDeleteButtonTitle.isEmpty && actionSheetTitle.isEmpty {
                return
            }
            let actionSheet = FSActionSheet(title: actionSheetTitle, delegate: nil, cancelButtonTitle: actionSheetCancelTitle, highlightedButtonTitle: actionSheetDeleteButtonTitle, otherButtonTitles: actionOtherButtonTitles)
            actionSheet.showWithSelectedCompletion({ [weak self] (selectedIndex) in
                if self?.delegate != nil {
                    self?.delegate?.photoBrowser!(self!, clickActionSheetIndex: selectedIndex, currentImageIndex: (self?.currentImageIndex)!)
                }
            })
            
            return
        }
    }
    
    // MARK: - private -- save image
    @objc private func saveImage() {
        let zoomingScrollView = zoomingScrollViewAtIndex(currentImageIndex)
        if zoomingScrollView.progress < 1.0 {
            saveImageTipLabel.text = FSPhotoBrowserLoadingImageText
            addSubview(saveImageTipLabel)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+1.0, execute: {
                self.saveImageTipLabel.removeFromSuperview()
            })
            return
        }
        UIImageWriteToSavedPhotosAlbum(zoomingScrollView.currentImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        addSubview(indicatorView)
        indicatorView.startAnimating()
        
    }
    
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeMutableRawPointer?) {
        indicatorView.removeFromSuperview()
        addSubview(saveImageTipLabel)
        if error != nil {
            saveImageTipLabel.text = FSPhotoBrowserSaveImageFailText
        } else {
            saveImageTipLabel.text = FSPhotoBrowserSaveImageSuccessText
        }
        // 延迟一秒执行
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+1.0) {
            self.saveImageTipLabel.removeFromSuperview()
        }
    }
    // MARK: - private ---loadimage
    private func showPhotos() {
        // 只有一张图片
        if imageCount == 1 {
            setUpImageForZoomingScrollViewAtIndex(0)
            return
        }
        
        let visibleBounds = scrollView.bounds
        var firstIndex = visibleBounds.equalTo(CGRect.zero) ? 0 : Int(floor(visibleBounds.origin.x/visibleBounds.size.width))
        var lastIndex = visibleBounds.equalTo(CGRect.zero) ? 0 : Int(floor((visibleBounds.origin.x+visibleBounds.size.width-1)/visibleBounds.size.width))
        
        if firstIndex < 0 {
            firstIndex = 0
        }
        if firstIndex >= imageCount {
            firstIndex = imageCount - 1
        }
        if lastIndex < 0 {
            lastIndex = 0
        }
        if lastIndex >= imageCount {
            lastIndex = imageCount - 1
        }
        
        // 回收不再显示的zoomingScrollView
        var zoomingScrollViewIndex = 0
        for view in visibleZoomingScrollViews {
            if let zoomingScrollView = view as? FSZoomingScrollView {
                zoomingScrollViewIndex = zoomingScrollView.tag - BaseTag
                if zoomingScrollViewIndex < firstIndex || zoomingScrollViewIndex > lastIndex {
                    reusableZoomingScrollViews.add(zoomingScrollView)
                    zoomingScrollView.prepareForReuse()
                    zoomingScrollView.removeFromSuperview()
                }
            }
        }
        
        // _visiblePhotoViews 减去 _reusablePhotoViews中的元素
        visibleZoomingScrollViews.minus(reusableZoomingScrollViews as! Set<AnyHashable>)
        while reusableZoomingScrollViews.count > 2 { // 循环利用池中最多保存两个可以用对象
            reusableZoomingScrollViews.remove(reusableZoomingScrollViews.anyObject()!)
        }
        
        // 展示图片
        for index in firstIndex...lastIndex {
            if !isShowingZoomingScrollViewAtIndex(index) {
                setUpImageForZoomingScrollViewAtIndex(index)
            }
        }
    }
    
    /// 判断指定的某个位置图片是否在显示
    private func isShowingZoomingScrollViewAtIndex(_ index: NSInteger) -> Bool {
        for view in visibleZoomingScrollViews {
            if let v = view as? FSZoomingScrollView {
                if (v.tag - BaseTag) == index {
                    return true
                }
            }
        }
        return false
    }
    
    /// 获取指定位置的FNZoomingScrollView , 三级查找,正在显示的池,回收池,创建新的并赋值
    ///
    /// - Parameter index: 指定位置索引
    private func zoomingScrollViewAtIndex(_ index: NSInteger) -> FSZoomingScrollView {
        for view in visibleZoomingScrollViews {
            if let v = view as? FSZoomingScrollView {
                if (v.tag - BaseTag) == index {
                    return v
                }
            }
        }
        let zoomingScrollView = dequeueReusableZoomingScrollView()
        setUpImageForZoomingScrollViewAtIndex(index)
        return zoomingScrollView
    }
    
    
    /// 加载指定位置的图片
    private func setUpImageForZoomingScrollViewAtIndex(_ index: NSInteger) {
        let zoomingScrollView = dequeueReusableZoomingScrollView()
        zoomingScrollView.zoomingScrollViewdelegate = self
        zoomingScrollView.addGestureRecognizer(UILongPressGestureRecognizer.init(target: self, action: #selector(longPress(_:))))
        zoomingScrollView.tag = BaseTag + index
        zoomingScrollView.frame = CGRect(x: scrollView.fs_width*CGFloat(index), y: 0, width: self.fs_width, height: self.fs_height)
        currentImageIndex = index
        if (highQualityImageURLForIndex(index) != nil) { // 如果提供了高清大图数据源,就去加载
            zoomingScrollView.setShowHighQualityImageWithURL(highQualityImageURLForIndex(index), placeholderImage: placeholderImageForIndex(index))
        } else if (assetForIndex(index) != nil) {
            let asset = assetForIndex(index)
            let imageRef = asset?.defaultRepresentation().fullScreenImage()
            zoomingScrollView.setShowImage(UIImage(cgImage: imageRef as! CGImage))
            imageRef?.release()
        } else {
            zoomingScrollView.setShowImage(placeholderImageForIndex(index))
        }
        
        visibleZoomingScrollViews.add(zoomingScrollView)
        scrollView.addSubview(zoomingScrollView)
    }
    
    /// 从缓存池中获取一个FSZoomingScrollView对象
    private func dequeueReusableZoomingScrollView() -> FSZoomingScrollView {
        var photoView = reusableZoomingScrollViews.anyObject() as? FSZoomingScrollView
        if photoView != nil {
            reusableZoomingScrollViews.remove(photoView!)
        } else {
            photoView = FSZoomingScrollView()
        }
        return photoView!
    }

    /// 获取指定位置的占位图片,和外界的数据源交互
    private func placeholderImageForIndex(_ index: NSInteger) -> UIImage {
        if datasource != nil && (datasource?.responds(to: #selector(datasource?.photoBrowser(_:placeholderImageForIndex:))))! {
            return (datasource?.photoBrowser!(self, placeholderImageForIndex: index))!
        } else if images.count > index {
            if let image = images[index] as? UIImage {
                return image
            } else {
                return placeholderImage
            }
        }
        return placeholderImage
    }
    
    /// 获取指定位置的占位图片,和外界的数据源交互
    private func highQualityImageURLForIndex(_ index: NSInteger) -> URL? {
        if datasource != nil && (datasource?.responds(to: #selector(datasource?.photoBrowser(_:highQualityImageURLForIndex:))))! {
            let url = datasource?.photoBrowser!(self, highQualityImageURLForIndex: index)
            if url == nil {
                // 高清大图URL数据 为空,请检查代码 , 图片索引:\(index)
                return nil
            }
            return url
        } else if images.count > index {
            if let url = images[index] as? URL {
                return url
            } else if let urlStr = images[index] as? String {
                return URL(string: urlStr)
            }
        }
        return nil
    }
    
    
    /// 获取指定位置的 ALAsset,获取图片
    private func assetForIndex(_ index: NSInteger) -> ALAsset? {
        if datasource != nil && (datasource?.responds(to: #selector(datasource?.photoBrowser(_:assetForIndex:))))! {
            return (datasource?.photoBrowser!(self, assetForIndex: index))!
        } else if images.count > index {
            if let asset = images[index] as? ALAsset {
                return asset
            } else {
                return nil
            }
        }
        return nil
    }
    
    /// 获取多图浏览,指定位置图片的UIImageView视图,用于做弹出放大动画和回缩动画
    private func sourceImageViewForIndex(_ index: NSInteger) -> UIView? {
        if datasource != nil && (datasource?.responds(to: #selector(datasource?.photoBrowser(_:sourceImageViewForIndex:))))! {
            return datasource?.photoBrowser!(self, sourceImageViewForIndex: index)
        }
        return nil
    }

    
    /// 第一个展示的图片 , 点击图片,放大的动画就是从这里来的
    private func showFirstImage() {
        /// // 获取到用户点击的那个UIImageView对象,进行坐标转化
        var startRect: CGRect
        if sourceImageView == nil {
            if datasource != nil && (datasource?.responds(to: #selector(datasource?.photoBrowser(_:sourceImageViewForIndex:))))! {
                sourceImageView = datasource?.photoBrowser!(self, sourceImageViewForIndex: currentImageIndex)
            } else {
                let maskBackView = photoBrowserWindow?.rootViewController?.view
                maskBackView?.alpha = 0.0
                UIView.animate(withDuration: 0.25, animations: {
                    maskBackView?.alpha = 1.0
                    self.alpha = 1.0
                })
                return // 需要提供源视图才能做弹出/退出图片浏览器的缩放动画
            }
        }
        startRect = (sourceImageView?.superview?.convert((sourceImageView?.frame)!, to: self))!
        
        let tempView = UIImageView()
        tempView.image = placeholderImageForIndex(currentImageIndex)
        tempView.frame = startRect
        addSubview(tempView)
        
        let targetRect: CGRect
        let image = sourceImageView?.image
        
        //TODO 完善image为空的闪退
        if image == nil {
            return //需要提供源视图才能做弹出/退出图片浏览器的缩放动画
        }
        let imageWidthHeightRatio = (image?.size.width)!/(image?.size.height)!
        let width = FSScreenWidth
        let height = FSScreenWidth/imageWidthHeightRatio
        let x = 0
        var y: CGFloat
        if height > FSScreenHeight {
            y = 0
        } else {
            y = (FSScreenHeight - height) * 0.5
        }
        targetRect = CGRect(x: CGFloat(x), y: y, width: width, height: height)
        scrollView.isHidden = true
        self.alpha = 1.0
        
        // 动画修改图片视图的frame , 居中同时放大
        UIView.animate(withDuration: FSPhotoBrowserHideImageAnimationDuration, animations: {
            tempView.frame = targetRect
        }) { (finished) in
            tempView.removeFromSuperview()
            self.scrollView.isHidden = false
        }
        
    }
    
}


// MARK: - FSZoomingScrollViewDelegate
extension FSPhotoBrowser: FSZoomingScrollViewDelegate {
    
    /// 单击图片,退出浏览
    func zoomingScrollView(_ zoomingScrollView: FSZoomingScrollView, singleTapDetected singleTap: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.15, animations: {
            self.saveImageTipLabel.alpha = 0.0
            self.indicatorView.alpha = 0.0
        }) { (finished) in
            self.saveImageTipLabel.removeFromSuperview()
            self.indicatorView.removeFromSuperview()
        }
        let currentIndex = zoomingScrollView.tag - BaseTag
        let sourceView = sourceImageViewForIndex(currentIndex)
        if sourceView == nil {
            dismiss()
            return
        }
        scrollView.isHidden = true
        pageControl.isHidden = true
        indexLabel.isHidden = true
        saveButton.isHidden = true
        
        let targetTemp = sourceView?.superview?.convert((sourceView?.frame)!, to: self)
        
        let tempView = UIImageView()
        tempView.contentMode = (sourceView?.contentMode)!
        tempView.clipsToBounds = true
        tempView.image = zoomingScrollView.currentImage
        tempView.frame = CGRect(x:  -zoomingScrollView.scrollView.contentOffset.x + zoomingScrollView.imageView.fs_x, y: -zoomingScrollView.scrollView.contentOffset.y+zoomingScrollView.imageView.fs_y, width: zoomingScrollView.imageView.fs_width, height: zoomingScrollView.imageView.fs_height)
        addSubview(tempView)
        
        UIApplication.shared.setStatusBarHidden(false, with: .fade)
        UIView.animate(withDuration: FSPhotoBrowserHideImageAnimationDuration, animations: {
            tempView.frame = targetTemp!
            self.backgroundColor = UIColor.clear
        }) { (finished) in
            self.removeFromSuperview()
            self.photoBrowserWindow?.rootViewController = nil
            self.photoBrowserWindow = nil
        }
        
    }
}


// MARK: - UIScrollViewDelegate
extension FSPhotoBrowser: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        showPhotos()
        let pageNum = Int(floor((scrollView.contentOffset.x+scrollView.bounds.size.width*0.5)/scrollView.bounds.size.width))
        currentImageIndex = (pageNum == imageCount) ? (pageNum - 1) : pageNum
        updateIndexContent()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNum = Int(floor((scrollView.contentOffset.x+scrollView.bounds.size.width*0.5)/scrollView.bounds.size.width))
        currentImageIndex = (pageNum == imageCount) ? (pageNum - 1) : pageNum
        updateIndexContent()
    }
    /// MARK: - 图片索引的显示内容和显隐逻辑
    /// 更新索引指示控件的显隐逻辑
    func updateIndexVisible() {
        switch browserStyle {
        case .PageControl:
            pageControl?.isHidden = false
            indexLabel?.isHidden = true
            saveButton?.isHidden = true
            break
        case .IndexLabel:
            pageControl?.isHidden = true
            indexLabel?.isHidden = false
            saveButton?.isHidden = true
            break
        case .Simple:
            pageControl?.isHidden = true
            indexLabel?.isHidden = false
            saveButton?.isHidden = false
            break
        }
        
        if imageCount == 1 && hidesForSinglePage == true {
            indexLabel?.isHidden = true
            pageControl?.isHidden = true
        }
    }
    
    /// 修改图片指示索引内容
    func updateIndexContent() {
        if let pageCtrl = pageControl as? UIPageControl {
            pageCtrl.currentPage = currentImageIndex
            let title = ("\(currentImageIndex+1) / \(imageCount)")
            indexLabel.text = title
        }
    }
}






