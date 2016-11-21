/*
 * QRCodeReader.swift
 *
 * Copyright 2014-present Yannick Loriot.
 * http://yannickloriot.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import UIKit

/// Overlay over the camera view to display the area (a square) where to scan the code.

enum BorderDirection {
    case TopRight
    case TopLeft
    case BottomRight
    case BottomLeft
}

final class ReaderOverlayView: UIView {
    
    var textLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
    
    func generateBorderLayer () -> CAShapeLayer {
        var overlay = CAShapeLayer()
        overlay.backgroundColor = UIColor.clear.cgColor
        overlay.fillColor       = UIColor.clear.cgColor
        overlay.strokeColor     = UIColor.white.cgColor
        overlay.lineWidth       = 3
        return overlay
    }
    
    private var layerContainer = CAShapeLayer()
    
    private var overlayBorderTopRight: CAShapeLayer? = nil
    private var overlayBorderTopLeft: CAShapeLayer? = nil
    private var overlayBorderBottomRight: CAShapeLayer? = nil
    private var overlayBorderBottomLeft: CAShapeLayer? = nil
    
    func initializeBorderLayers () {
        overlayBorderTopRight = generateBorderLayer()
        overlayBorderTopLeft = generateBorderLayer()
        overlayBorderBottomRight = generateBorderLayer()
        overlayBorderBottomLeft = generateBorderLayer()
    }
    
    func borderLayersCreated () -> Bool {
        return (overlayBorderBottomLeft != nil) &&
            (overlayBorderBottomRight != nil) &&
            (overlayBorderTopLeft != nil) &&
            (overlayBorderTopRight != nil)
    }
    
    func addBorderLayers () -> Bool {
        if (self.borderLayersCreated()) {
            layerContainer.addSublayer(overlayBorderBottomLeft!)
            layerContainer.addSublayer(overlayBorderBottomRight!)
            layerContainer.addSublayer(overlayBorderTopRight!)
            layerContainer.addSublayer(overlayBorderTopLeft!)
            layer.addSublayer(layerContainer)
            return true
        } else {
            return false
        }
    }
    
    func createPathForBorderLayer (_ currentRect: CGRect, _ direction: BorderDirection, _ currentPathTmp: UIBezierPath?, _ rect: CGRect?) -> UIBezierPath {
        var yStart = false
        var yEnd = false
        var xStart = false
        var xEnd = false
        var startPoint: CGPoint = CGPoint()
        var endPoint: CGPoint = CGPoint()
        var startAngle: CGFloat = 0
        var endAngle: CGFloat = 0
        var radius: CGFloat = currentRect.size.width / 2.0
        let center = CGPoint(x: currentRect.origin.x + radius, y: currentRect.origin.y + radius)
        
        switch direction {
        case .TopLeft:
            yStart = true
            xEnd = true
            startAngle = CGFloat(2*M_PI*0.50)
            endAngle = CGFloat(2*M_PI*0.75)
            break
        case .TopRight:
            xEnd = true
            yEnd = true
            startAngle = CGFloat(2*M_PI*0.75)
            endAngle = CGFloat(2*M_PI*1.0)
            break
        case .BottomLeft:
            xStart = true
            yStart = true
            startAngle = CGFloat(2*M_PI*0.25)
            endAngle = CGFloat(2*M_PI*0.50)
            break
        case .BottomRight:
            xStart = true
            yEnd = true
            startAngle = 0
            endAngle = CGFloat(2*M_PI*0.25)
            break
        }
        
        startPoint = CGPoint(x: currentRect.origin.x + ( xStart ? currentRect.size.width : 0.0 ), y: currentRect.origin.y + ( yStart ? currentRect.size.height : 0.0 ))
        endPoint = CGPoint(x: currentRect.origin.x + ( xEnd ? currentRect.size.width : 0.0 ), y: currentRect.origin.y + ( yEnd ? currentRect.size.height : 0.0 ))
        if (rect != nil){
            startPoint = CGPoint(x: currentRect.origin.x + rect!.size.width + ( xStart ? currentRect.size.width : 0.0 ), y: currentRect.origin.y + ( yStart ? currentRect.size.height : 0.0 ))
        }
        var currentPath: UIBezierPath? = nil
        if (currentPathTmp == nil){
            currentPath = UIBezierPath()
            currentPath!.move(to: startPoint)
        } else {
            currentPath = currentPathTmp
            currentPath!.addLine(to: startPoint)
        }
        // Put a circle path in the middle
        currentPath!.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        currentPath!.addLine(to: endPoint)
        
        //return UIBezierPath(roundedRect: currentRect, cornerRadius: 5)
        return currentPath!
    }
    
    func createFrameForBorder (_ parentFrame: CGRect, _ direction : BorderDirection, _ percentage: CGFloat) -> CGRect {
        var result: CGRect? = nil
        let width = parentFrame.size.width * percentage
        let height = parentFrame.size.width * percentage
        let xOffset: CGFloat = (parentFrame.size.width/2.0) - (width/2.0)
        let yOffset: CGFloat = (parentFrame.size.height/2.0) - (height/2.0)
        var withXOffset = false
        var withYOffset = false
        switch direction {
        case .TopLeft:
            break
        case .TopRight:
            withXOffset = true
            break
        case .BottomLeft:
            withYOffset = true
            break
        case .BottomRight:
            withXOffset = true
            withYOffset = true
            break
        }
        result = CGRect(x: (parentFrame.origin.x/2.0) + (withXOffset ? xOffset:0.0), y: (parentFrame.origin.y/2) + (withYOffset ? yOffset:0.0), width: width, height: height)
        return result!
    }
    
    func createFramesForBorders (_ parentFrame: CGRect, percentage: CGFloat) -> Bool {
        if (self.borderLayersCreated()) {
            overlayBorderTopRight!.frame = createFrameForBorder(parentFrame, .TopRight, percentage)
            overlayBorderTopLeft!.frame = createFrameForBorder(parentFrame, .TopLeft, percentage)
            overlayBorderBottomRight!.frame = createFrameForBorder(parentFrame, .BottomRight, percentage)
            overlayBorderBottomLeft!.frame = createFrameForBorder(parentFrame, .BottomLeft, percentage)
            return true
        } else {
            return false
        }
    }
    
    func createPathsForBorders () -> Bool {
        if (self.borderLayersCreated()) {
            overlayBorderTopRight!.path = createPathForBorderLayer(overlayBorderTopRight!.frame, .TopRight, nil, nil).cgPath
            overlayBorderTopLeft!.path = createPathForBorderLayer(overlayBorderTopLeft!.frame, .TopLeft, nil, nil).cgPath
            overlayBorderBottomRight!.path = createPathForBorderLayer(overlayBorderBottomRight!.frame, .BottomRight, nil, nil).cgPath
            overlayBorderBottomLeft!.path = createPathForBorderLayer(overlayBorderBottomLeft!.frame, .BottomLeft, nil, nil).cgPath
            return true
        } else {
            return false
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)  // Workaround for init in iOS SDK 8.3
        initializeBorderLayers()
        addBorderLayers()
        // Add UIlabel to the camera screen
        textLabel.textAlignment = .center
        textLabel.textColor = UIColor.white
        textLabel.font = UIFont(name: "Helvetica Neue", size: 17)
        textLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        textLabel.numberOfLines = 2
        textLabel.text = "Sync with UnifyID Chrome Extension"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeBorderLayers()
        addBorderLayers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeBorderLayers()
        addBorderLayers()
    }
    
    override func draw(_ rect: CGRect) {
        var innerRect = rect.insetBy(dx: 50, dy: 50)
        let minSize   = min(innerRect.width, innerRect.height)
        
        if innerRect.width != minSize {
            innerRect.origin.x   += (innerRect.width - minSize) / 2
            innerRect.size.width = minSize
        }
        else if innerRect.height != minSize {
            innerRect.origin.y    += (innerRect.height - minSize) / 2
            innerRect.size.height = minSize
        }
        
        let offsetRect = innerRect.offsetBy(dx: 0, dy: -40)
        textLabel.center = CGPoint(x: innerRect.midX, y: innerRect.midY + innerRect.midY*0.45)
        self.addSubview(textLabel)
        createFramesForBorders(offsetRect, percentage: 0.15)
        createPathsForBorders()
        
    }
}
