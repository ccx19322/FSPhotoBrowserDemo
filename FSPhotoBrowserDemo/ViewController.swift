//
//  ViewController.swift
//  FSPhotoBrowserDemo
//
//  Created by chen cx on 2019/4/2.
//  Copyright © 2019 chen cx. All rights reserved.
//

import UIKit
import SnapKit
import Kingfisher

class ViewController: UIViewController {

    var imageView1: UIImageView!
    var imageView2: UIImageView!
    var imageView3: UIImageView!
    lazy var sourceImages: [UIImageView] = {
        return [imageView1,imageView2,imageView3]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        imageView1 = UIImageView()
        imageView1.contentMode = .scaleAspectFill
        imageView1.clipsToBounds = true
        let url1 = URL(string: "http://wimg.spriteapp.cn/picture/2018/0521/5b024e06ca5b3_wpd_34.jpg")
        imageView1.kf.setImage(with: url1)
        view.addSubview(imageView1)
        imageView1.snp.makeConstraints { (make) in
            make.top.equalTo(100)
            make.width.height.equalTo(100)
            make.left.equalTo(50)
        }
        
        imageView2 = UIImageView()
        imageView2.contentMode = .scaleAspectFill
        imageView2.clipsToBounds = true
        let url2 = URL(string: "http://wimg.spriteapp.cn/picture/2018/0521/5b024e06ca5b3_wpd_34.jpg")
        imageView2.kf.setImage(with: url2)
        view.addSubview(imageView2)
        imageView2.snp.makeConstraints { (make) in
            make.top.equalTo(210)
            make.width.height.equalTo(100)
            make.left.equalTo(50)
        }
        
        imageView3 = UIImageView()
        imageView3.contentMode = .scaleAspectFill
        imageView3.clipsToBounds = true
        let url3 = URL(string: "http://wimg.spriteapp.cn/picture/2018/0521/5b024e06ca5b3_wpd_34.jpg")
        imageView3.kf.setImage(with: url3)
        view.addSubview(imageView3)
        imageView3.snp.makeConstraints { (make) in
            make.top.equalTo(320)
            make.width.height.equalTo(100)
            make.left.equalTo(50)
        }
        
        imageView1.isUserInteractionEnabled = true
        imageView1.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tagClick(_:))))
        
    }
    
    
    @objc private func tagClick(_ tapGesture: UITapGestureRecognizer) {
        let images = ["http://wimg.spriteapp.cn/picture/2018/0521/5b024e06ca5b3_wpd_34.jpg","http://wimg.spriteapp.cn/picture/2018/0521/5b024e06ca5b3_wpd_34.jpg","http://wimg.spriteapp.cn/picture/2018/0521/5b024e06ca5b3_wpd_34.jpg"]
        let imagev = tapGesture.self.view as! UIImageView
        let browser = FSPhotoBrowser()
        browser.currentImageIndex = 0
        browser.images = images
        browser.datasource = self
        browser.sourceImageView = imagev
        browser.show()
        
        browser.setActionSheetWithTitle("请选择", delegate: nil, cancelButtonTitle: "取消", deleteButtonTitle: "删除", otherButtonTitles: ["男","女"])
    }
    


}


extension ViewController: FSPhotoBrowserDatasource {
    
    func photoBrowser(_ browser: FSPhotoBrowser, placeholderImageForIndex index: NSInteger) -> UIImage {
        return sourceImages[index].image!
    }
    
    func photoBrowser(_ browser: FSPhotoBrowser, sourceImageViewForIndex index: NSInteger) -> UIImageView {
        return sourceImages[index]
    }
    
}

