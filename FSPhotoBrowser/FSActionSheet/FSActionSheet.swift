//
//  FSActionSheet.swift
//  SwiftDemo
//
//  Created by chen FS on 2018/5/13.
//  Copyright © 2018年 chen cx. All rights reserved.
//

import UIKit

// MARK: - ActionSheet Config

/// 选择选项Block回调
typealias FSActionSheetHandler = (_ selectedIndex: NSInteger) -> Void

/// 选项类型枚举
enum FSActionSheetType: UInt {
    case Normal = 0     //正常状态
    case Highlighted    //高亮状态
}

/// 内容便宜枚举
enum FSContentAlignment: UInt {
    case left = 0       // 内容紧靠左边
    case center         // 内容居中
    case right          // 内容靠右边
}


/// FSActionSheet Config
private struct FSActionSheetConfig {
    static var DefaultMargin: CGFloat = 10 ///< 默认边距 (标题四边边距, 选项靠左或靠右时距离边缘的距离), default is 10.
    static var ContentMaxScale: CGFloat   = 0.65 ///< 弹窗内容高度与屏幕高度的默认比例, default is 0.65.
    static var RowHeight: CGFloat = 44 ///< 行高, default is 44.
    static var TitleLineSpacing: CGFloat  = 2.5 ///< 标题行距, default is 2.5.
    static var TitleKernSpacing: CGFloat  = 0.5 ///< 标题字距, default is 0.5.
    static var ItemTitleFontSize: CGFloat = 16 ///< 选项文字字体大小, default is 16.
    static var ItemContentSpacing: CGFloat  = 5 ///< 选项图片和文字的间距, default is 5.
    // color
    static var TitleColor = "#888888" ///< 标题颜色, default is #888888
    static var BackColor = "#E8E8ED" ///< 背景颜色, default is #E8E8ED
    static var RowNormalColor = "#FBFBFE" ///< 单元格背景颜色, default is #FBFBFE
    static var RowHighlightedColor = "#F1F1F5" ///< 选中高亮颜色, default is #F1F1F5
    static var RowTopLineColor = "#D7D7D8" ///< 单元格顶部线条颜色, default is #D7D7D8
    static var ItemNormalColor = "#000000" ///< 选项默认颜色, default is #000000
    static var ItemHighlightedColor = "#E64340" ///< 选项高亮颜色, default is #E64340
    
    static func colorWithString(_ aColorString: String)-> UIColor {
        
        if aColorString.isEmpty {
            return UIColor.clear
        }
        
        var cString: String = aColorString.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).uppercased() 
        
        if (cString.hasPrefix("#")) {
            cString = (cString as NSString).substring(from: 1)
        }
        
        if ((cString as NSString).length != 6) {
            return UIColor.clear
        }
        
        let rString = (cString as NSString).substring(to: 2)
        let gString = ((cString as NSString).substring(from: 2) as NSString).substring(to: 2)
        let bString = ((cString as NSString).substring(from: 4) as NSString).substring(to: 2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0
        Scanner(string: rString).scanHexInt32(&r)
        Scanner(string: gString).scanHexInt32(&g)
        Scanner(string: bString).scanHexInt32(&b)
        
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
    }
    
    /// iphoneX 距离底部的触控安全距离
    static func LandscapeBottomHeight() -> CGFloat {
        if UIScreen.main.bounds.size.width == 812 && UIScreen.main.bounds.size.height == 375 {
            return 21
        }
        return 0
    }
    
    /// iphoneX 距离底部的触控安全距离
    static func PortraitBottomHeight() -> CGFloat {
        if UIScreen.main.bounds.size.width == 375 && UIScreen.main.bounds.size.height == 812 {
            return 23
        }
        return 0
    }
    
}


// MARK: - FSActionSheet
@objc protocol FSActionSheetDelegate: NSObjectProtocol {
    @objc optional
    func FSActionSheet(_ actionSheet: FSActionSheet, selectedIndex: NSInteger)
}
class FSActionSheet: UIView {
    ///< 代理对象
    weak var delegate: FSActionSheetDelegate?
    var  contentAlignment: FSContentAlignment = .center ///< 默认是FSContentAlignmentCenter.
    {
        didSet {
            self.updateTitleAttributeText()
        }
    }
    var hideOnTouchOutside = true ///< 是否开启点击半透明层隐藏弹窗, 默认为YES.
    
    // MARK: - Private
    private var title: String!
    private var cancelTitle: String!
    private var items: [FSActionSheetItem]!
    private var selectedHandler: FSActionSheetHandler?
    
    lazy private var popupWindow: UIWindow = {
        let window = UIWindow.init(frame: UIScreen.main.bounds)
        window.windowLevel = UIWindow.Level(CGFloat(MAXFLOAT)) // UIWindowLevelStatusBar+1 //修改层级保证可以弹出
        window.rootViewController = UIViewController()
        self.popupVC = window.rootViewController
        self.controllerView = self.popupVC.view
        return window
    }()
    private var popupVC: UIViewController!
    private var controllerView: UIView!
    private var backView: UIView!
    lazy private var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = self.backgroundColor
        tableView.autoresizingMask = .flexibleWidth
        tableView.estimatedRowHeight = 0.0
        tableView.estimatedSectionHeaderHeight = 0.0
        tableView.estimatedSectionFooterHeight = 0.0
        tableView.register(FSActionSheetCell.self, forCellReuseIdentifier: kFSActionSheetCellIdentifier)
        if !self.title.isEmpty {
            tableView.tableHeaderView = self.headerView()
        }
        return tableView
    }()
    private var titleLable: UILabel!
    
    private var heightConstraint: NSLayoutConstraint! ///< 内容高度约束
    
    private let kFSActionSheetSectionHeight: CGFloat = 10 ///< 分区间距
    private let kFSActionSheetCellIdentifier = "kFSActionSheetCellIdentifier"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// @author ChenFS
    ///单文本选项快速初始化
    /// - Parameters:
    ///   - title: 标题
    ///   - delegate: 代理
    ///   - cancelButtonTitle: 取消按钮标题
    ///   - highlightedButtonTitle: 高亮按钮标题
    ///   - otherButtonTitles: 其他按钮标题集合
    init(title: String, delegate: FSActionSheetDelegate?, cancelButtonTitle: String, highlightedButtonTitle: String?, otherButtonTitles: [String]? = nil) {
        super.init(frame: CGRect.zero)
        commonInit()
        
        var titleItems = [FSActionSheetItem]()
        // 普通按钮
        for otherTitle in otherButtonTitles! {
            if !otherTitle.isEmpty {
                titleItems.append(FSActionSheetItem.TitleItemMake(.Normal, otherTitle))
            }
        }
        // 高亮按钮，高亮按钮放在最下面
        if highlightedButtonTitle != nil {
            titleItems.append(FSActionSheetItem.TitleItemMake(.Highlighted, highlightedButtonTitle!))
        }
        
        self.title = title.isEmpty ? "" : title
        self.delegate = delegate
        self.cancelTitle = cancelButtonTitle.isEmpty ? "取消" : cancelButtonTitle
        self.items = titleItems
        
        addSubview(tableView)
    }
    
    
    /// @author ChenFS
    ///在外部组装选项按钮item
    /// - Parameters:
    ///   - title: 标题
    ///   - cancelTitle: 取消按钮标题
    ///   - items: 选项按钮Item
    init(title: String, cancelTitle: String, items: [FSActionSheetItem]?) {
        
        super.init(frame: CGRect.zero)
        
        commonInit()
        
        self.title = title.isEmpty ? "" : title
        self.cancelTitle = cancelTitle.isEmpty ? "取消" : cancelTitle
        self.items = (items != nil) ? items : []
        
        addSubview(tableView)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.tableView.frame = self.bounds
    }
    
    private func commonInit() {
        self.backgroundColor = FSActionSheetConfig.colorWithString(FSActionSheetConfig.BackColor)
        self.translatesAutoresizingMaskIntoConstraints = false //允许约束
        
        self.popupWindow.bounds = UIScreen.main.bounds
        
        // 监听屏幕旋转
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc private func orientationDidChange(_ notification: NSNotification) {
        if !title.isEmpty {
            // 更新头部标题高度
            let newHeaderHeight = heightForHeaderView()
            var newHeaderRect = tableView.tableHeaderView?.frame
            newHeaderRect?.size.height = newHeaderHeight
            tableView.tableHeaderView?.frame = newHeaderRect!
            self.tableView.tableHeaderView = self.tableView.tableHeaderView
        }
        
        // 适配当前内容高度
    }
    
    // MARK: - private
    // 计算title在设定宽度下的富文本高度
    private func heightForHeaderView() -> CGFloat {
        let labelHeight = titleLable.attributedText?.boundingRect(with: CGSize.init(width: currentScreenWidth() - FSActionSheetConfig.DefaultMargin*2, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, context: nil).size.height
        let headerHeight = ceil(labelHeight!) + FSActionSheetConfig.DefaultMargin*2
        return headerHeight
    }
    
    // 整个弹窗内容的高度
    private func contentHeight() -> CGFloat {
        let titleHeight = !title.isEmpty ? heightForHeaderView() : 0
        let rowHeightSum = CGFloat(items.count + 1)*FSActionSheetConfig.RowHeight+kFSActionSheetSectionHeight
        let contentHeight = titleHeight+rowHeightSum
        
        return contentHeight
    }
    
    // 适配屏幕高度, 弹出窗高度不应该高于屏幕的设定比例
    private func fixContentHeight() {
        let contentMaxHeight = currentScreenHeight() + FSActionSheetConfig.ContentMaxScale
        var contentHeight = self.contentHeight()
        if contentHeight > contentMaxHeight {
            contentHeight = contentMaxHeight
            self.tableView.isScrollEnabled = true
        } else {
            self.tableView.isScrollEnabled = false
        }
        
        // 判断屏幕方向
        let orientation = popupVC.preferredInterfaceOrientationForPresentation
        var bottomHeight: CGFloat = 0
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            bottomHeight = FSActionSheetConfig.LandscapeBottomHeight()
        } else {
            bottomHeight = FSActionSheetConfig.PortraitBottomHeight()
        }
        heightConstraint.constant = contentHeight + bottomHeight
    }
    
    /// 屏幕当前宽度
    private func currentScreenWidth() -> CGFloat {
        let currentScreenWidth: CGFloat!
        let screenSize = UIScreen.main.bounds.size
        let screenWidth = fmin(screenSize.width, screenSize.height) // 该值为屏幕竖屏下的屏幕宽度
        let screenHeight = fmax(screenSize.width, screenSize.height) // 该值为屏幕竖屏下的屏幕高度
        // 判断屏幕方向
        let orientation = popupVC.preferredInterfaceOrientationForPresentation
        // 横屏
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            currentScreenWidth = CGFloat(screenHeight)
        } else {
            currentScreenWidth = CGFloat(screenWidth)
        }
        return currentScreenWidth
        
    }
    
    /// 屏幕当前高度
    private func currentScreenHeight() -> CGFloat {
        let currentScreenHeight: CGFloat!
        let screenSize = UIScreen.main.bounds.size
        let screenWidth = fmin(screenSize.width, screenSize.height) // 该值为屏幕竖屏下的屏幕宽度
        let screenHeight = fmax(screenSize.width, screenSize.height) // 该值为屏幕竖屏下的屏幕高度
        // 判断屏幕方向
        let orientation = popupVC.preferredInterfaceOrientationForPresentation
        // 横屏
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            currentScreenHeight = CGFloat(screenWidth)
        } else {
            currentScreenHeight = CGFloat(screenHeight)
        }
        return currentScreenHeight
        
    }
    
    // 适配标题偏移方向
    private func updateTitleAttributeText() {
        if title.isEmpty || title == nil {
            return
        }
        
        // 富文本相关配置
        let attributeRange = NSMakeRange(0, title.count)
        let titleFont = UIFont.systemFont(ofSize: 14)
        let titleTextColor = FSActionSheetConfig.colorWithString(FSActionSheetConfig.TitleColor)
        let lineSpacing = FSActionSheetConfig.TitleLineSpacing
        let kernSpacing = FSActionSheetConfig.TitleKernSpacing
        
        let titleAttributeString = NSMutableAttributedString(string: title)
        let titleStyle = NSMutableParagraphStyle()
        // 行距
        titleStyle.lineSpacing = lineSpacing
        // 内容偏移样式
        switch contentAlignment {
        case .left:
            titleStyle.alignment = .left
            break
        case .center:
            titleStyle.alignment = .center
            break
        case .right:
            titleStyle.alignment = .right
            break
        }
        titleAttributeString.addAttribute(NSAttributedString.Key.paragraphStyle, value: titleStyle, range: attributeRange)
        // 字距
        titleAttributeString.addAttribute(NSAttributedString.Key.kern, value: kernSpacing, range: attributeRange)
        // 字体
        titleAttributeString.addAttribute(.font, value: titleFont, range: attributeRange)
        // 颜色
        titleAttributeString.addAttribute(.foregroundColor, value: titleTextColor, range: attributeRange)
        titleLable.attributedText = titleAttributeString
    }
    
    // 点击背景半透明遮罩层隐藏
    @objc private func backViewGesture() {
        self.hideWithCompletion(nil)
    }
    
    // 隐藏
    private func hideWithCompletion(_ completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            self.backView.alpha = 0
            var newFrame        = self.frame
            newFrame.origin.y   = self.controllerView.frame.size.height+self.controllerView.frame.origin.y
            self.frame          = newFrame
        }) { (finished) in
            UIApplication.shared.delegate?.window!?.makeKey()
            if completion != nil {
                completion!()
            }
            self.backView.removeFromSuperview()
            self.backView = nil
            self.tableView.removeFromSuperview()
            //self.tableView = nil
            self.removeFromSuperview()
            //self.popupWindow = nil
            self.selectedHandler = nil
        }
    }
    
    /// @brief 单展示, 不绑定block回调
    func Show() {
        self.showWithSelectedCompletion(nil)
    }
    
    
    func showWithSelectedCompletion(_ selectedHandler: FSActionSheetHandler?) {
        self.selectedHandler = selectedHandler
        
        backView = UIView()
        backView.alpha = 0
        backView.backgroundColor = UIColor.black
        backView.isUserInteractionEnabled = hideOnTouchOutside
        backView.translatesAutoresizingMaskIntoConstraints = false
        backView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backViewGesture)))
        controllerView.addSubview(backView)
        controllerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[backView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["backView":backView]))
        controllerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[backView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["backView":backView]))
        
        self.tableView.reloadData()
        
        // 判断屏幕方向
        let orientation = popupVC.preferredInterfaceOrientationForPresentation
        var bottomHeight: CGFloat = 0
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            bottomHeight = FSActionSheetConfig.LandscapeBottomHeight()
        } else {
            bottomHeight = FSActionSheetConfig.PortraitBottomHeight()
        }
        var contentHeight = self.tableView.contentSize.height + bottomHeight
        // 适配屏幕高度
        let contentMaxHeight = self.popupWindow.frame.size.height*FSActionSheetConfig.ContentMaxScale+bottomHeight
        if contentHeight > contentMaxHeight {
            self.tableView.isScrollEnabled = true
            contentHeight = contentMaxHeight
        }
        controllerView.addSubview(self)
        
        let selfW = controllerView.frame.size.width
        let selfH = contentHeight
        let selfX = 0
        let selfY = controllerView.frame.origin.y + controllerView.frame.size.height
        self.frame = CGRect(x: CGFloat(selfX), y: selfY, width: selfW, height: selfH)
        
        self.popupWindow.makeKeyAndVisible()
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            self.backView.alpha = 0.38
            var newFrame = self.frame
            newFrame.origin.y = self.controllerView.frame.size.height+self.controllerView.frame.origin.y-selfH
            self.frame = newFrame
        }) { (finished) in
            // constraint
            self.controllerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[self]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["self":self]))
            self.controllerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[self]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["self":self]))
            self.heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: contentHeight)
            self.controllerView.addConstraint(self.heightConstraint)
            
        }
    }
    
    
    private func headerView() -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = FSActionSheetConfig.colorWithString(FSActionSheetConfig.RowNormalColor)
        
        // 标题
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.backgroundColor = headerView.backgroundColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        self.titleLable = titleLabel
        // 设置富文本标题内容
        self.updateTitleAttributeText()
        
        /// 标题内容边距 (ps: 要修改这个边距不要在这里修改这个labelMargin, 要到配置类中修改 FSActionSheetDefaultMargin, 不然可能出现界面适配错乱).
        let labelMargin = FSActionSheetConfig.DefaultMargin
        // 计算内容高度
        let headerHeight = self.heightForHeaderView()
        headerView.frame = CGRect.init(x: 0, y: 0, width: self.popupWindow.frame.size.width, height: headerHeight)
        
        // titleLable constraint
        headerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-labelMargin-[titleLabel]-labelMargin-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: ["labelMargin":labelMargin], views: ["titleLabel":titleLabel]))
        
        headerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-labelMargin-[titleLabel]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: ["labelMargin":labelMargin], views: ["titleLabel":titleLabel]))
        
        return headerView
        
    }
    
    
    
    private func dictForViews(views:[UIView]) -> [String : UIView] {
        var count:UInt32 = 0
        var dicts:[String : UIView] = [:]
        
        let ivars = class_copyIvarList(self.classForCoder, &count)
        for i in 0...Int(count)-1 {
            let obj = object_getIvar(self, ivars![i])
            if let temp = obj as? UIView{
                _=views.contains(temp)
                let name = String(cString: ivar_getName(ivars![i])!)
                dicts[name] = temp
                if dicts.count == views.count{ break }
            }
        }
        free(ivars)
        
        return dicts
        
    }
    
    
}


// MARK: - FSActionSheet UITableViewDelegate, UITableViewDataSource

extension FSActionSheet: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? 1 : items.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FSActionSheetConfig.RowHeight
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? kFSActionSheetSectionHeight : CGFloat.leastNormalMagnitude
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kFSActionSheetCellIdentifier)
        return cell!
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let sheetCell = cell as! FSActionSheetCell
        if indexPath.section == 0 {
            sheetCell.item = items[indexPath.row]
            sheetCell.hideTopLine = false
            // 当无标题时隐藏第一单元格的顶部线条
            if indexPath.row == 0 && (title == nil || title.isEmpty) {
                sheetCell.hideTopLine = true
            }
        } else {
            // 默认取消的单元格没有附带icon
            var cancelItem = FSActionSheetItem.TitleItemMake(.Normal, cancelTitle)
            // 如果其它单元格中附带icon的话则添加上默认的取消icon.
            for item in items {
                if item.image != nil {
                    cancelItem = FSActionSheetItem.TitleWithImageItemMake(.Normal, UIImage(named: "FSActionSheet_cancel")!, cancelTitle)
                    break
                }
            }
            sheetCell.item = cancelItem
            sheetCell.hideTopLine = true
        }
        sheetCell.contentAlignment = contentAlignment
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 延迟0.1秒隐藏让用户既看到点击效果又不影响体验
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.1) {
            self.hideWithCompletion({
                if indexPath.section == 0 {
                    if self.selectedHandler != nil {
                        self.selectedHandler!(indexPath.row)
                    }
                    if self.delegate != nil && (self.delegate?.responds(to: #selector(self.delegate?.FSActionSheet(_:selectedIndex:))))! {
                        self.delegate?.FSActionSheet!(self, selectedIndex: indexPath.row)
                    }
                }
            })
        }
    }
    
}


class FSActionSheetCell: UITableViewCell {
    
    var contentAlignment: FSContentAlignment = .center {
        didSet {
            // 更新button的图片和标题Edge
            self.updateButtonContentEdge()
            // 设置内容偏移
            switch contentAlignment {
                // 居左
            case .left:
                self.titleButton.contentHorizontalAlignment = .left
                self.titleButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: FSActionSheetConfig.DefaultMargin, bottom: 0, right: -FSActionSheetConfig.DefaultMargin)
                break
                // 居中
            case .center:
                self.titleButton.contentHorizontalAlignment = .center
                self.titleButton.contentEdgeInsets = UIEdgeInsets.zero
                break
                // 居右
            case .right:
                self.titleButton.contentHorizontalAlignment = .right
                self.titleButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: -FSActionSheetConfig.DefaultMargin, bottom: 0, right: FSActionSheetConfig.DefaultMargin)
                break
            }
        }
    }
    var item: FSActionSheetItem! {
        didSet {
            // 前景色设置, 如果有自定义前景色则使用自定义的前景色, 否则使用预配置的颜色值.
            let tintColor: UIColor!
            if item.tintColor != nil {
                tintColor = item.tintColor
            } else {
                if item.type == .Normal {
                    tintColor =  FSActionSheetConfig.colorWithString(FSActionSheetConfig.ItemNormalColor)
                    
                } else {
                    tintColor = FSActionSheetConfig.colorWithString(FSActionSheetConfig.ItemHighlightedColor)
                }
            }
            self.titleButton.tintColor = tintColor
            // 调整图片与标题的间距
            let isImage = item.image != nil
            self.titleButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: isImage ? -FSActionSheetConfig.ItemContentSpacing/2 : 0, bottom: isImage ? 1 : 0, right: isImage ? FSActionSheetConfig.ItemContentSpacing/2 : 0)
            self.titleButton.titleEdgeInsets = UIEdgeInsets(top: isImage ? 1 : 0, left: isImage ? FSActionSheetConfig.ItemContentSpacing/2 : 0, bottom: 0, right: isImage ? -FSActionSheetConfig.ItemContentSpacing/2 : 0)

            //设置图片与标题
            self.titleButton.setTitle(item.title, for: .normal)
            self.titleButton.setImage(item.image, for: .normal)
        }
    }
    var hideTopLine: Bool! ///< 是否隐藏顶部线条
    {
        didSet {
            topLine.isHidden = hideTopLine
        }
    }
    
    private var titleButton: UIButton!
    private var topLine: UIView! ///< 顶部线条
    
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            self.contentView.backgroundColor = FSActionSheetConfig.colorWithString(FSActionSheetConfig.RowHighlightedColor)
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                self.contentView.backgroundColor = self.backgroundColor
            })
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor =  FSActionSheetConfig.colorWithString(FSActionSheetConfig.RowNormalColor)
        self.contentView.backgroundColor = self.backgroundColor
        self.selectionStyle = .none
        self.contentAlignment = .center
        self.setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    private func setupSubviews() {
        titleButton = UIButton(type: .system)
        titleButton.tintColor = FSActionSheetConfig.colorWithString(FSActionSheetConfig.ItemNormalColor)
        titleButton.titleLabel?.font = UIFont.systemFont(ofSize: FSActionSheetConfig.ItemTitleFontSize)
        titleButton.isUserInteractionEnabled = false
        titleButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(titleButton)
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[titleButton]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["titleButton":titleButton]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[titleButton]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["titleButton":titleButton]))
        
        // 顶部线条
        topLine = UIView()
        topLine.backgroundColor =  FSActionSheetConfig.colorWithString(FSActionSheetConfig.RowTopLineColor)
        topLine.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(topLine)
        let lineHeight = 1/UIScreen.main.scale /// <线条高度
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[topLine]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["topLine":topLine]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[topLine(lineHeight)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: ["lineHeight":lineHeight], views: ["topLine":topLine]))
        
        
    }
    
    // 更新button图片与标题的edge
    private func updateButtonContentEdge() {
        if (item.image == nil) {
            return
        }
        if contentAlignment == .right {
            let titleWidth = (titleButton.title(for: .normal)! as NSString).size(withAttributes: [NSAttributedString.Key.font: titleButton.titleLabel?.font as Any]).width
            titleButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: titleWidth, bottom: 1, right: -titleWidth)
            titleButton.titleEdgeInsets = UIEdgeInsets(top: 1, left: -(item.image?.size.width)!-FSActionSheetConfig.ItemContentSpacing, bottom: 0, right: (item.image?.size.width)!+FSActionSheetConfig.ItemContentSpacing)
        } else {
            titleButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -FSActionSheetConfig.ItemContentSpacing/2, bottom: 1, right: FSActionSheetConfig.ItemContentSpacing/2)
            titleButton.titleEdgeInsets = UIEdgeInsets(top: 1, left: FSActionSheetConfig.ItemContentSpacing/2, bottom: 0, right: -FSActionSheetConfig.ItemContentSpacing/2)
        }
    }
    
    
    private func dictForViews(_ views:[UIView]) -> [String : UIView] {
        var count:UInt32 = 0
        var dicts:[String : UIView] = [:]
        
        let ivars = class_copyIvarList(self.classForCoder, &count)
        for i in 0...Int(count)-1 {
            let obj = object_getIvar(self, ivars![i])
            if let temp = obj as? UIView{
                _=views.contains(temp)
                let name = String(cString: ivar_getName(ivars![i])!)
                dicts[name] = temp
                if dicts.count == views.count{ break }
            }
        }
        return dicts
        
//        var dicts:[String : UIView] = [:]
//        for subview in views {
//            let viewName = NSStringFromClass(subview.classForCoder)
//            dicts[viewName] = subview
//        }
//        return dicts
        
    }
    
    
    
}





class FSActionSheetItem: NSObject {
    var type: FSActionSheetType! ///< 选项类型, 有 默认 和 高亮 两种类型.
    var image: UIImage? ///< 选项图标, 建议image的size为 @2x: 46x46, @3x: 69x69.
    var title: String? ///< 选项标题
    var tintColor: UIColor? ///< 选项前景色, 如果设置了这个颜色的话, 则无论选项设置的图标是什么颜色都会被修改为当前设置的这个颜色,
    ///< 同时这个颜色也会是标题的文本颜色.
    
    override init() {
        super.init()
    }
    
    init(type: FSActionSheetType, image: UIImage? = nil, title: String? = nil, tintColor: UIColor? = nil) {
        super.init()
        self.type = type
        self.image = image
        self.title = title
        self.tintColor = tintColor
    }
    
    /// @author ChenFS
    /// 单标题的选项
    /// - Parameters:
    ///   - type: 类型
    ///   - title: 标题
    static func TitleItemMake(_ type: FSActionSheetType, _ title: String) -> FSActionSheetItem {
        return FSActionSheetItem(type: type, title: title)
    }
    
    
    /// @author ChenFS
    ///标题和图标的选项
    /// - Parameters:
    ///   - type: 类型
    ///   - _image: 图片
    ///   - title: 标题
    static func TitleWithImageItemMake(_ type: FSActionSheetType, _ image: UIImage, _ title: String ) -> FSActionSheetItem {
        return FSActionSheetItem(type: type, image: image, title: title)
    }
    
    
    /// @author ChenFS
    ///单标题且自定义前景色的选项
    /// - Parameters:
    ///   - type: 类型
    ///   - title: 标题
    ///   - tintColor: 自定义前景色
    static func TitleWithColorItemMake(_ type: FSActionSheetType,_ title: String, _ tintColor: UIColor) -> FSActionSheetItem {
        return FSActionSheetItem(type: type, title: title, tintColor: tintColor)
    }
    
    /// @author ChenFS
    ///单标题且自定义前景色的选项
    /// - Parameters:
    ///   - type: 类型
    ///   - image: 图片
    ///   - title: 标题
    ///   - tintColor: 自定义前景色
    static func TitleWithColorItemMake(_ type: FSActionSheetType,_ image: UIImage,_ title: String, _ tintColor: UIColor) -> FSActionSheetItem {
        return FSActionSheetItem(type: type,image:image,title:title,tintColor:tintColor)
    }

    
    
}








