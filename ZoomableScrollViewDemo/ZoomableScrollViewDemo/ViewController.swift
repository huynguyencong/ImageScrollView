//
//  ViewController.swift
//  ZoomableScrollViewDemo
//
//  Created by Nguyen Cong Huy on 3/5/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import UIKit
import ZoomableScrollView

class ViewController: UIViewController {
    
    @IBOutlet weak var ZoomableScrollView: ZoomableScrollView!
    var images = [UIImage]()
    var index = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nameSet = ["dog-0.jpg", "dog-1.jpg", "dog-2.jpg", "dog-3.jpg", "dog-4.jpg", "IMG_7774.JPG"]
        self.images = nameSet.compactMap { UIImage(named: $0) }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ZoomableScrollView.imageContentMode = .aspectFit
        ZoomableScrollView.initialOffset = .center
        ZoomableScrollView.display(image: images[index])
    }

    @IBAction func previousButtonTap(_ sender: AnyObject) {
        index = (index - 1 + images.count)%images.count
        ZoomableScrollView.display(image: images[index])
    }
    
    @IBAction func nextButtonTap(_ sender: AnyObject) {
        index = (index + 1)%images.count
        ZoomableScrollView.display(image: images[index])
    }
    
}

