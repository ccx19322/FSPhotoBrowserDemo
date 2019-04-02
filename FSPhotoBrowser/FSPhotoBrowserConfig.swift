//
//  FSPhotoBrowserConfig.swift
//  SwiftDemo
//
//  Created by iOSgo on 2018/5/16.
//  Copyright © 2018年 chen FS. All rights reserved.
//

import Foundation
import UIKit

/// 图片浏览器的样式
public enum FSPhotoBrowserStyle: UInt {
    /// 长按图片弹出功能组件,底部一个PageControl
    case PageControl = 1
    /// 长按图片弹出功能组件,顶部一个索引UILabel
    case IndexLabel = 2
    /// 没有长按图片弹出的功能组件,顶部一个索引UILabel,底部一个保存图片按钮
    case Simple = 3
}

/// pageControl的位置
public enum FSPhotoBrowserPageControlAligment: UInt {
    /// pageControl在右边
    case Right = 1
    /// pageControl 中间
    case Center = 2
    case Left = 3
}

/// pageControl的样式
enum FSPhotoBrowserPageControlStyle: UInt {
    /// 系统自带经典样式
    case Classic = 1
    /// 动画效果pagecontrol
    case Animated = 2
    /// 不显示pagecontrol
    case None = 3
}

/// 进度视图类型类型
enum FSProgressViewMode: UInt {
    /// 圆环形
    case LoopDiagram = 1
    /// 圆饼型
    case PieDiagram = 2
}


// 图片保存成功提示文字
let FSPhotoBrowserSaveImageSuccessText = " ^_^ 保存成功 "
// 图片保存失败提示文字
let FSPhotoBrowserSaveImageFailText = " >_< 保存失败 "
// 网络图片加载失败的提示文字
let FSPhotoBrowserLoadNetworkImageFail = ">_< 图片加载失败"
let FSPhotoBrowserLoadingImageText = " >_< 图片加载中,请稍后 "

// browser背景颜色
let FSPhotoBrowserBackgrounColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
// browser 图片间的margin
let FSPhotoBrowserImageViewMargin = 10
// browser中显示图片动画时长
let FSPhotoBrowserShowImageAnimationDuration = 0.25
// browser中显示图片动画时长
let FSPhotoBrowserHideImageAnimationDuration = 0.25

// 图片下载进度指示进度显示样式（FNProgressViewModeLoopDiagram 环形，FNProgressViewModePieDiagram 饼型）
let FSProgressViewProgressMode = FSProgressViewMode.LoopDiagram
// 图片下载进度指示器背景色
let FSProgressViewBackgroundColor = UIColor.clear
// 图片下载进度指示器圆环/圆饼颜色
let FSProgressViewStrokeColor = UIColor.white
// 图片下载进度指示器内部控件间的间距
let FSProgressViewItemMargin = 10
// 圆环形图片下载进度指示器 环线宽度
let FSProgressViewLoopDiagramLineWidth = 8
