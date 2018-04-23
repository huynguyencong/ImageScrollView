# ZoomableScrollView

A control to help you display an view, with zoomable and scrollable features easily.

### About
When you make an application, which has a photo viewer feature, the photo viewer usually needs to have zoomable and scrollable features, to allow the user to view more photo details.  
This control help you display image, with zoomable and scrollable features easily.

#### Compatible

- iOS 7 and later (requires iOS 8 if you want to add it to project using CocoaPod)
- Swift 3.0 (version 1.3), 2.0 (version 1.2 and prior)

### Usage

#### Cocoapod
Add below line to Podfile:  

```
pod 'ZoomableScrollView'
```  
and run below command in Terminal to install:  
`pod install`

Note: If above pod isn't working, try using below pod definition in Podfile:  
`pod 'ZoomableScrollView', :git => 'https://github.com/tucan9389/ZoomableScrollView.git'`
#### Manual
In iOS 7, you cannot use Cocoapod to install. In this case, you need add it manually. Simply, add file `ImageSrollView.swift` in folder `Sources` to your project

#### Simple to use
Drag an UIScrollView to your storyboard, change Class and Module in Identity Inspector to ZoomableScrollView. Also, create an IBOutlet in your source file.

![image](http://s10.postimg.org/jd12ztvkp/Tut1.jpg)

```
import ZoomableScrollView
```

```
@IBOutlet weak var ZoomableScrollView: ZoomableScrollView!
```

```
let myImage = UIImage(named: "my_image_name")
ZoomableScrollView.display(image: myImage)
```
That's all. Now try zooming and scrolling to see the result.

Note: If your image is aligned left instead of center, try calling below method:

```superViewOfZoomableScrollView.layoutIfNeeded()```

`superViewOfZoomableScrollView` is the view that ZoomableScrollView is added to.

### About this source
This open source is based on PhotoScroller demo avaiable on Apple's site. The original source is written in Objective C. This source rewrite uses Swift, and adds some new features:
- Double tap to zoom feature.
- Smoother. Fixed bug when zooming out, the control auto zooms from center, and not from the corner.

### License
ZoomableScrollView is released under the MIT license. See LICENSE for details. Copyright © tucan9389
