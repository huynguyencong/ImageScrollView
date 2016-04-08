//
//  ImageScrollView.swift
//  Beauty
//
//  Created by Nguyen Cong Huy on 1/19/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import UIKit

public class ImageScrollView: UIScrollView, UIScrollViewDelegate {
    
    static let kZoomInFactorFromMinWhenDoubleTap: CGFloat = 2
    
    var subViewsLaidOut: Bool = false
    
    var zoomView: UIImageView? = nil
    var imageSize: CGSize = CGSizeZero
    private var pointToCenterAfterResize: CGPoint = CGPointZero
    private var scaleToRestoreAfterResize: CGFloat = 1.0
    var maxScaleFromMinScale: CGFloat = 3.0
    private var isNeedAnimateWhileSetZoomViewFrame = false
    
    override public var frame: CGRect {
        willSet {
            if CGRectEqualToRect(frame, newValue) == false && CGRectEqualToRect(newValue, CGRectZero) == false && CGSizeEqualToSize(imageSize, CGSizeZero) == false {
                prepareToResize()
            }
        }
        
        didSet {
            if CGRectEqualToRect(frame, oldValue) == false && CGRectEqualToRect(frame, CGRectZero) == false && CGSizeEqualToSize(imageSize, CGSizeZero) == false {
                recoverFromResizing()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    private func initialize() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = UIScrollViewDecelerationRateFast
        delegate = self
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        guard zoomView != nil else {
            return
        }
        
        var frameToCenter = zoomView!.frame
        
        // center horizontally
        if frameToCenter.size.width < bounds.width {
            frameToCenter.origin.x = (bounds.width - frameToCenter.size.width) / 2
        }
        else {
            frameToCenter.origin.x = 0
        }
        
        // center vertically
        if frameToCenter.size.height < bounds.height {
            frameToCenter.origin.y = (bounds.height - frameToCenter.size.height) / 2
        }
        else {
            frameToCenter.origin.y = 0
        }
        
        if isNeedAnimateWhileSetZoomViewFrame {
            isNeedAnimateWhileSetZoomViewFrame = false
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.zoomView!.frame = frameToCenter
            })
        }
        else {
            zoomView!.frame = frameToCenter
        }
        
        if !subViewsLaidOut {
            setMaxMinZoomScalesForCurrentBounds()
            subViewsLaidOut = true
        }
    }
    
    private func prepareToResize() {
        let boundsCenter = CGPoint(x: CGRectGetMidX(bounds), y: CGRectGetMidY(bounds))
        pointToCenterAfterResize = convertPoint(boundsCenter, toView: zoomView)
        
        scaleToRestoreAfterResize = zoomScale
        
        // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
        // allowable scale when the scale is restored.
        if scaleToRestoreAfterResize <= minimumZoomScale + CGFloat(FLT_EPSILON) {
            scaleToRestoreAfterResize = 0
        }
    }
    
    private func recoverFromResizing() {
        setMaxMinZoomScalesForCurrentBounds()
        
        // restore zoom scale, first making sure it is within the allowable range.
        let maxZoomScale = max(minimumZoomScale, scaleToRestoreAfterResize)
        zoomScale = min(maximumZoomScale, maxZoomScale)
        
        // restore center point, first making sure it is within the allowable range.
        
        // convert our desired center point back to our own coordinate space
        let boundsCenter = convertPoint(pointToCenterAfterResize, toView: zoomView)
        
        // calculate the content offset that would yield that center point
        var offset = CGPoint(x: boundsCenter.x - bounds.size.width/2.0, y: boundsCenter.y - bounds.size.height/2.0)
        
        // restore offset, adjusted to be within the allowable range
        let maxOffset = maximumContentOffset()
        let minOffset = minimumContentOffset()
        
        var realMaxOffset = min(maxOffset.x, offset.x)
        offset.x = max(minOffset.x, realMaxOffset)
        
        realMaxOffset = min(maxOffset.y, offset.y)
        offset.y = max(minOffset.y, realMaxOffset)
        
        contentOffset = offset
    }
    
    private func maximumContentOffset() -> CGPoint {
        return CGPointMake(contentSize.width - bounds.width, contentSize.height - bounds.height)
    }
    
    private func minimumContentOffset() -> CGPoint {
        return CGPointZero
    }

    // MARK: - UIScrollViewDelegate
    
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return zoomView
    }
    
    // MARK: - Display image
    
    public func displayImage(image: UIImage) {

        if let zoomView = zoomView {
            zoomView.removeFromSuperview()
        }
        
        zoomView = UIImageView(image: image)
        zoomView!.userInteractionEnabled = true
        addSubview(zoomView!)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ImageScrollView.doubleTapGestureRecognizer(_:)))
        tapGesture.numberOfTapsRequired = 2
        zoomView!.addGestureRecognizer(tapGesture)
        configureImageForSize(image.size)
    }
    
    private func configureImageForSize(size: CGSize) {
        imageSize = size
        contentSize = imageSize
        if subViewsLaidOut {
            setMaxMinZoomScalesForCurrentBounds()
        }
        zoomScale = minimumZoomScale
        contentOffset = CGPointZero
    }
    
    private func setMaxMinZoomScalesForCurrentBounds() {
        // calculate min/max zoomscale
        let xScale = bounds.width / imageSize.width    // the scale needed to perfectly fit the image width-wise
        let yScale = bounds.height / imageSize.height   // the scale needed to perfectly fit the image height-wise
        
        // fill width if the image and phone are both portrait or both landscape; otherwise take smaller scale
        let imagePortrait = imageSize.height > imageSize.width
        let phonePortrait = bounds.height >= bounds.width

        var minScale = (imagePortrait == phonePortrait) ? xScale : min(xScale, yScale)
        
        let maxScale = maxScaleFromMinScale*minScale
        
        // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
        if minScale > maxScale {
            minScale = maxScale
        }
        
        maximumZoomScale = maxScale
        minimumZoomScale = minScale * 0.999 // the multiply factor to prevent user cannot scroll page while they use this control in UIPageViewController
    }
    
    // MARK: - Gesture
    
    @objc private func doubleTapGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {
        // zoom out if it bigger than middle scale point. Else, zoom in
        if zoomScale >= maximumZoomScale / 2.0 {
            setZoomScale(minimumZoomScale, animated: true)
        }
        else {
            let center = gestureRecognizer.locationInView(gestureRecognizer.view)
            let zoomRect = zoomRectForScale(ImageScrollView.kZoomInFactorFromMinWhenDoubleTap * minimumZoomScale, center: center)
            zoomToRect(zoomRect, animated: true)
        }
        
        isNeedAnimateWhileSetZoomViewFrame = true
    }
    
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRectZero
        
        // the zoom rect is in the content view's coordinates.
        // at a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
        // as the zoom scale decreases, so more content is visible, the size of the rect grows.
        zoomRect.size.height = frame.size.height / scale
        zoomRect.size.width  = frame.size.width  / scale
        
        // choose an origin so as to get the right center.
        zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0)
        zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
    
    public func refresh() {
        if let image = zoomView?.image {
            displayImage(image)
        }
    }
}
