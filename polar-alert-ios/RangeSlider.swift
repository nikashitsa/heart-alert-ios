// Based on https://github.com/warchimede/RangeSlider

import UIKit
import QuartzCore

class RangeSliderTrackLayer: CALayer {
  weak var rangeSlider: RangeSlider?
  
  override func draw(in ctx: CGContext) {
    guard let slider = rangeSlider else {
      return
    }
    
      ctx.setLineWidth(1.0)
      ctx.setStrokeColor(slider.trackTintColor.cgColor)
      let thumbRadius = bounds.height
      ctx.move(to: CGPoint(x: thumbRadius, y: bounds.height / 2))
      ctx.addLine(to: CGPoint(x: bounds.width - thumbRadius, y: bounds.height / 2))
      ctx.strokePath()
    
      ctx.setLineWidth(1.0)
      ctx.setStrokeColor(slider.trackHighlightTintColor.cgColor)
      let lowerValuePosition = slider.lowerThumbLayer.isHidden ? thumbRadius : CGFloat(slider.positionForValue(slider.lowerValue))
      let upperValuePosition = CGFloat(slider.positionForValue(slider.upperValue))
      
      ctx.move(to: CGPoint(x: lowerValuePosition, y: bounds.height / 2))
      ctx.addLine(to: CGPoint(x: upperValuePosition, y: bounds.height / 2))
      ctx.strokePath()
  }
}

class RangeSliderThumbLayer: CALayer {
  
  var highlighted: Bool = false {
    didSet {
      setNeedsDisplay()
    }
  }
  weak var rangeSlider: RangeSlider?
  
  var strokeColor: UIColor = UIColor.white {
    didSet {
      setNeedsDisplay()
    }
  }
  var lineWidth: CGFloat = 1.0 {
    didSet {
      setNeedsDisplay()
    }
  }
  
  override func draw(in ctx: CGContext) {
    guard let slider = rangeSlider else {
      return
    }
      
    ctx.setLineWidth(lineWidth)
    ctx.setStrokeColor(strokeColor.cgColor)
    ctx.setFillColor(slider.thumbTintColor.cgColor)
    let circleRect = bounds.insetBy(dx: 2.0, dy: 2.0)
    ctx.addEllipse(in: circleRect)
    ctx.fillPath()
    ctx.addEllipse(in: circleRect)
    ctx.strokePath()
  }
}

@IBDesignable
public class RangeSlider: UIControl {
    
  @IBInspectable public var minimumValue: Double = 0.0 {
    willSet(newValue) {
      assert(newValue < maximumValue, "RangeSlider: minimumValue should be lower than maximumValue")
    }
    didSet {
      updateLayerFrames()
    }
  }
  
  @IBInspectable public var maximumValue: Double = 1.0 {
    willSet(newValue) {
      assert(newValue > minimumValue, "RangeSlider: maximumValue should be greater than minimumValue")
    }
    didSet {
      updateLayerFrames()
    }
  }
  
  @IBInspectable public var lowerValue: Double = 0.2 {
    didSet {
      if lowerValue < minimumValue {
        lowerValue = minimumValue
        lowerThumbLayer.isHidden = true
      }
      updateLayerFrames()
    }
  }
  
  @IBInspectable public var upperValue: Double = 0.8 {
    didSet {
      if upperValue > maximumValue {
        upperValue = maximumValue
      }
      updateLayerFrames()
    }
  }
  
  var gapBetweenThumbs: Double {
      return 0
  }
  
  @IBInspectable public var trackTintColor: UIColor = UIColor(white: 0.9, alpha: 1.0) {
    didSet {
      trackLayer.setNeedsDisplay()
    }
  }
  
    @IBInspectable public var trackHighlightTintColor: UIColor = UIColor.red {
    didSet {
      trackLayer.setNeedsDisplay()
    }
  }
  
  @IBInspectable public var thumbTintColor: UIColor = UIColor.black {
    didSet {
      lowerThumbLayer.setNeedsDisplay()
      upperThumbLayer.setNeedsDisplay()
    }
  }
  
  @IBInspectable public var thumbBorderColor: UIColor = UIColor.gray {
    didSet {
      lowerThumbLayer.strokeColor = thumbBorderColor
      upperThumbLayer.strokeColor = thumbBorderColor
    }
  }
  
    @IBInspectable public var thumbBorderWidth: CGFloat = 1.0 {
    didSet {
      lowerThumbLayer.lineWidth = thumbBorderWidth
      upperThumbLayer.lineWidth = thumbBorderWidth
    }
  }
  
  @IBInspectable public var curvaceousness: CGFloat = 1.0 {
    didSet {
      if curvaceousness < 0.0 {
        curvaceousness = 0.0
      }
      
      if curvaceousness > 1.0 {
        curvaceousness = 1.0
      }
      
      trackLayer.setNeedsDisplay()
      lowerThumbLayer.setNeedsDisplay()
      upperThumbLayer.setNeedsDisplay()
    }
  }
  
  fileprivate var previouslocation = CGPoint()
  
  fileprivate let trackLayer = RangeSliderTrackLayer()
  fileprivate let lowerThumbLayer = RangeSliderThumbLayer()
  fileprivate let upperThumbLayer = RangeSliderThumbLayer()
  
  fileprivate var thumbWidth: CGFloat {
    return CGFloat(bounds.height)
  }
  
  override public var frame: CGRect {
    didSet {
      updateLayerFrames()
    }
  }
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    initializeLayers()
  }
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    initializeLayers()
  }
  
  override public func layoutSublayers(of: CALayer) {
    super.layoutSublayers(of:layer)
    updateLayerFrames()
  }
  
  fileprivate func initializeLayers() {
    layer.backgroundColor = UIColor.clear.cgColor
    
    trackLayer.rangeSlider = self
    trackLayer.contentsScale = UIScreen.main.scale
    layer.addSublayer(trackLayer)
    

    if (!lowerThumbLayer.isHidden) {
        lowerThumbLayer.rangeSlider = self
        lowerThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(lowerThumbLayer)
    }
    
    upperThumbLayer.rangeSlider = self
    upperThumbLayer.contentsScale = UIScreen.main.scale
    layer.addSublayer(upperThumbLayer)
  }
  
  func updateLayerFrames() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    
    trackLayer.frame = bounds.insetBy(dx: 0.0, dy: bounds.height/3)
    trackLayer.setNeedsDisplay()
    
    let lowerThumbCenter = CGFloat(positionForValue(lowerValue))
    lowerThumbLayer.frame = CGRect(x: lowerThumbCenter - thumbWidth/2.0, y: 0.0, width: thumbWidth, height: thumbWidth)
    lowerThumbLayer.setNeedsDisplay()
    
    let upperThumbCenter = CGFloat(positionForValue(upperValue))
    upperThumbLayer.frame = CGRect(x: upperThumbCenter - thumbWidth/2.0, y: 0.0, width: thumbWidth, height: thumbWidth)
    upperThumbLayer.setNeedsDisplay()
    
    CATransaction.commit()
  }
  
  func positionForValue(_ value: Double) -> Double {
    return Double(bounds.width - thumbWidth) * (value - minimumValue) /
    (maximumValue - minimumValue) + Double(thumbWidth/2.0)
  }
  
  func boundValue(_ value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
    return min(max(value, lowerValue), upperValue)
  }
  
  
  // MARK: - Touches
  
  override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    previouslocation = touch.location(in: self)
    let middle = (maximumValue + minimumValue) / 2
    if (lowerThumbLayer.frame.contains(previouslocation) && upperThumbLayer.frame.contains(previouslocation)) {
      if (lowerValue > middle) {
        lowerThumbLayer.highlighted = true
      } else {
        upperThumbLayer.highlighted = true
      }
    } else if lowerThumbLayer.frame.contains(previouslocation) && !lowerThumbLayer.isHidden {
      lowerThumbLayer.highlighted = true
    } else if upperThumbLayer.frame.contains(previouslocation) {
      upperThumbLayer.highlighted = true
    }
    return lowerThumbLayer.highlighted || upperThumbLayer.highlighted
  }
  
  override public func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    let location = touch.location(in: self)
    
    // Determine by how much the user has dragged
    let deltaLocation = Double(location.x - previouslocation.x)
    let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - bounds.height)
    
    previouslocation = location
    
    // Update the values
    if lowerThumbLayer.highlighted {
      lowerValue = boundValue(lowerValue + deltaValue, toLowerValue: minimumValue, upperValue: upperValue - gapBetweenThumbs)
    } else if upperThumbLayer.highlighted {
      upperValue = boundValue(upperValue + deltaValue, toLowerValue: lowerValue + gapBetweenThumbs, upperValue: maximumValue)
    }
      
    sendActions(for: .valueChanged)
    return true
  }
  
  override public func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    lowerThumbLayer.highlighted = false
    upperThumbLayer.highlighted = false
  }
}

