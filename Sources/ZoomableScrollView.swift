//
//  ZoomableScrollView.swift
//  Beauty
//
//  Created by Nguyen Cong Huy on 1/19/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import UIKit

open class ZoomableScrollView: UIScrollView {
    
    @objc public enum ZoomMode: Int {
        case defaultFit
        case aspectFill
        case aspectFit
        case widthFill
        case heightFill
    }
    
    @objc public enum Offset: Int {
        case begining
        case center
    }
    
    static let kZoomInFactorFromMinWhenDoubleTap: CGFloat = 2
    
    @objc open var zoomMode: ZoomMode = .aspectFit
    @objc open var initialOffset: Offset = .begining
    
    @objc public private(set) var contentView: UIView? = nil

    fileprivate var pointToCenterAfterResize: CGPoint = CGPoint.zero
    fileprivate var scaleToRestoreAfterResize: CGFloat = 1.0
    var maxScaleFromMinScale: CGFloat = 3.0
    
    
    private var _maximumZoomScale: CGFloat? = nil
    open override var maximumZoomScale: CGFloat {
        get {
            if let maximumZoomScale = self._maximumZoomScale {
                return maximumZoomScale
            } else {
                return super.maximumZoomScale
            }
        }
        set(newValue) {
            self._maximumZoomScale = newValue
            super.maximumZoomScale = newValue
        }
    }
    private var _minimumZoomScale: CGFloat? = nil
    open override var minimumZoomScale: CGFloat {
        get {
            if let minimumZoomScale = self._minimumZoomScale {
                return minimumZoomScale
            } else {
                return super.minimumZoomScale
            }
        }
        set(newValue) {
            self._minimumZoomScale = newValue
            super.minimumZoomScale = newValue
        }
    }
    
    
    override open var frame: CGRect {
        willSet {
            if frame.equalTo(newValue) == false && newValue.equalTo(CGRect.zero) == false && contentSize.equalTo(CGSize.zero) == false {
                prepareToResize()
            }
        }
        
        didSet {
            if frame.equalTo(oldValue) == false && frame.equalTo(CGRect.zero) == false && contentSize.equalTo(CGSize.zero) == false {
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func initialize() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = UIScrollViewDecelerationRateFast
        delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(ZoomableScrollView.changeOrientationNotification), name: Notification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    @objc public func adjustFrameToCenter() {
        
        guard let unwrappedZoomView = contentView else {
            return
        }
        
        var frameToCenter = unwrappedZoomView.frame
        
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
        
        unwrappedZoomView.frame = frameToCenter
    }
    
    fileprivate func prepareToResize() {
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        pointToCenterAfterResize = convert(boundsCenter, to: contentView)
        
        scaleToRestoreAfterResize = zoomScale
        
        // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
        // allowable scale when the scale is restored.
        if scaleToRestoreAfterResize <= minimumZoomScale + CGFloat(Float.ulpOfOne) {
            scaleToRestoreAfterResize = 0
        }
    }
    
    fileprivate func recoverFromResizing() {
        setMaxMinZoomScalesForCurrentBounds()
        
        // restore zoom scale, first making sure it is within the allowable range.
        let maxZoomScale = max(minimumZoomScale, scaleToRestoreAfterResize)
        zoomScale = min(maximumZoomScale, maxZoomScale)
        
        // restore center point, first making sure it is within the allowable range.
        
        // convert our desired center point back to our own coordinate space
        let boundsCenter = convert(pointToCenterAfterResize, to: contentView)
        
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
    
    fileprivate func maximumContentOffset() -> CGPoint {
        return CGPoint(x: contentSize.width - bounds.width,y:contentSize.height - bounds.height)
    }
    
    fileprivate func minimumContentOffset() -> CGPoint {
        return CGPoint.zero
    }

    // MARK: - Display view
    
    @objc open func display(view: UIView) {
        
        if let zoomView = contentView {
            zoomView.removeFromSuperview()
        }
        
        contentView = view
        contentView!.isUserInteractionEnabled = true
        addSubview(contentView!)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ZoomableScrollView.doubleTapGestureRecognizer(_:)))
        tapGesture.numberOfTapsRequired = 2
        contentView!.addGestureRecognizer(tapGesture)
        
        configureContentForSize(view.frame.size)
        
    }
    
    @objc open func display(image: UIImage) {
        display(view: UIImageView(image: image))
    }
    
    fileprivate func configureContentForSize(_ size: CGSize) {
        contentSize = size
        setMaxMinZoomScalesForCurrentBounds()
        zoomScale = minimumZoomScale
        
        switch initialOffset {
        case .begining:
            contentOffset =  CGPoint.zero
        case .center:
            let xOffset = contentSize.width < bounds.width ? 0 : (contentSize.width - bounds.width)/2
            let yOffset = contentSize.height < bounds.height ? 0 : (contentSize.height - bounds.height)/2

            switch zoomMode {
            case .defaultFit:
                contentOffset =  CGPoint.zero
            case .aspectFit:
                contentOffset =  CGPoint.zero
            case .aspectFill:
                contentOffset = CGPoint(x: xOffset, y: yOffset)
            case .heightFill:
                contentOffset = CGPoint(x: xOffset, y: 0)
            case .widthFill:
                contentOffset = CGPoint(x: 0, y: yOffset)
            }
        }
    }
    
    fileprivate func setMaxMinZoomScalesForCurrentBounds() {
        // calculate min/max zoomscale
        let xScale = bounds.width / contentSize.width    // the scale needed to perfectly fit the content view width-wise
        let yScale = bounds.height / contentSize.height   // the scale needed to perfectly fit the content view height-wise
    
        var minScale: CGFloat = 1
        
        switch zoomMode {
        case .defaultFit:
            minScale = min(xScale, yScale) > 1 ? 1 : min(xScale, yScale)
        case .aspectFill:
            minScale = max(xScale, yScale)
        case .aspectFit:
            minScale = min(xScale, yScale)
        case .widthFill:
            minScale = xScale
        case .heightFill:
            minScale = yScale
        }
        
        
        let maxScale = maxScaleFromMinScale*minScale
        
        // don't let minScale exceed maxScale. (If the content view is smaller than the screen, we don't want to force it to be zoomed.)
        if minScale > maxScale {
            minScale = maxScale
        }
        
        super.maximumZoomScale = _maximumZoomScale ?? maxScale
        super.minimumZoomScale = (_minimumZoomScale ?? minScale) * 0.999 // the multiply factor to prevent user cannot scroll page while they use this control in UIPageViewController
    }
    
    // MARK: - Gesture
    
    @objc func doubleTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // zoom out if it bigger than middle scale point. Else, zoom in
        if zoomScale >= maximumZoomScale / 2.0 {
            setZoomScale(minimumZoomScale, animated: true)
        }
        else {
            let center = gestureRecognizer.location(in: gestureRecognizer.view)
            let zoomRect = zoomRectForScale(ZoomableScrollView.kZoomInFactorFromMinWhenDoubleTap * minimumZoomScale, center: center)
            zoom(to: zoomRect, animated: true)
        }
    }
    
    fileprivate func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        
        // the zoom rect is in the content view's coordinates.
        // at a zoom scale of 1.0, it would be the size of the ZoomableScrollView's bounds.
        // as the zoom scale decreases, so more content is visible, the size of the rect grows.
        zoomRect.size.height = frame.size.height / scale
        zoomRect.size.width  = frame.size.width  / scale
        
        // choose an origin so as to get the right center.
        zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0)
        zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
    
    open func refresh() {
        if let view = contentView {
            display(view: view)
        }
    }
    
    // MARK: - Actions
    
    @objc func changeOrientationNotification() {
        configureContentForSize(contentSize)
    }
}

extension ZoomableScrollView: UIScrollViewDelegate{
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        adjustFrameToCenter()
    }
    
}
