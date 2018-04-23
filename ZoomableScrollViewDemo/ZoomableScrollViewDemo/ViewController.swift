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
        
        for i in 0..<5 {
            if let image = UIImage(named: "dog-\(i).jpg") {
                images.append(image)
            }
        }
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

