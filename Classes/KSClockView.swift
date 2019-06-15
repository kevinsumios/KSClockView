//
//  KSClockView.swift
//  Demo
//
//  Created by Kevin Sum on 30/5/2019.
//  Copyright © 2019 Kevin Sum. All rights reserved.
//

import UIKit

@objc protocol KSClockViewDelegate {
    func ksClockView(clockView: KSClockView, updating hour: Int, minute: Int)
    func ksClockView(clockView: KSClockView, didUpdate hour: Int, minute: Int)
}

@IBDesignable
class KSClockView: UIView {
    
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var minuteView: UIView!
    @IBOutlet weak var minuteHand: KSClockHand!
    @IBOutlet weak var hourView: UIView!
    @IBOutlet weak var hourHand: KSClockHand!
    @IBOutlet var minuteRecognizer: UIPanGestureRecognizer!
    @IBOutlet var hourRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var handMinuteImage: UIImageView!
    @IBOutlet weak var handHourImage: UIImageView!
    @IBOutlet weak var handHourCenterX: NSLayoutConstraint!
    @IBOutlet weak var handHourCenterY: NSLayoutConstraint!
    @IBOutlet weak var handMinuteCenterX: NSLayoutConstraint!
    @IBOutlet weak var handMinuteCenterY: NSLayoutConstraint!
    @IBOutlet weak var handHourHeight: NSLayoutConstraint!
    @IBOutlet weak var handMinuteHeight: NSLayoutConstraint!
    @IBOutlet weak var clockViewDelegate: KSClockViewDelegate?
    
    @IBInspectable var faceImage: UIImage?
    @IBInspectable var hourHandImage: UIImage?
    @IBInspectable var minuteHandImage: UIImage?
    @IBInspectable var round: Bool = false
    @IBInspectable var interactable: Bool {
        didSet {
            minuteRecognizer.isEnabled = interactable
            hourRecognizer.isEnabled = interactable
        }
    }
    
    var view: UIView!
    var bundle: Bundle!
    var beginPoints: [KSClockHand: CGPoint] = [:]
    var hour: Int = 0
    var minute: Int = 0
    
    required init?(coder aDecoder: NSCoder) {
        interactable = false
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        interactable = false
        super.init(frame: frame)
        setup()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        hour = Calendar.current.component(.hour, from: Date())
        minute = Calendar.current.component(.minute, from: Date())
        let (hourPoint, minutePoint) = updateTransform()
        beginPoints = [minuteHand: minutePoint,
                       hourHand: hourPoint]
        
        // set images
        bgImageView.image = faceImage
        handHourImage.image = hourHandImage
        handMinuteImage.image = minuteHandImage
        if round {
            let radius = bgImageView.frame.width/2
            bgImageView.layer.cornerRadius = radius
            bgImageView.layer.masksToBounds = true
        }
    }
    
    private func loadViewFromNib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        if (nib.instantiate(withOwner: self, options: nil).count > 0) {
            let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
            return view
        } else {
            return UIView(frame: .zero)
        }
    }
    
    private func setup() {
        bundle = Bundle(for: KSClockView.self)
        if let resourcePath = bundle.path(forResource: "KSClockView", ofType: "bundle") {
            if let resourcesBundle = Bundle(path: resourcePath) {
                bundle = resourcesBundle
            }
        }
        faceImage = UIImage(named: "ksclockview_face.png", in: bundle, compatibleWith: nil)
        hourHandImage = UIImage(named: "ksclockview_hourhand.png", in: bundle, compatibleWith:  nil)
        minuteHandImage = UIImage(named: "ksclockview_minutehand.png", in: bundle, compatibleWith:  nil)
        
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth,
                                 UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)
    }
    
    func updateTransform() -> (CGPoint, CGPoint) {
        let dayMinute = CGFloat(60*hour+minute)
        let hourAngle = dayMinute*CGFloat.pi/360.0
        let minuteAngle = CGFloat(minute)*CGFloat.pi/30
        let hourPoint = CGPoint(x: sin(hourAngle)*hourHand.long, y: cos(hourAngle)*hourHand.long)
        let minutePoint = CGPoint(x: sin(minuteAngle)*minuteHand.long, y: cos(minuteAngle)*minuteHand.long)
        self.hourView.transform = CGAffineTransform(rotationAngle: hourAngle)
        self.minuteView.transform = CGAffineTransform(rotationAngle: minuteAngle)
        
        return (hourPoint, minutePoint)
    }
    
    @IBAction func didPanView(_ sender: UIPanGestureRecognizer) {
        var translation = sender.translation(in: view);
        translation = CGPoint(x: translation.x, y: -translation.y)
        if let handView = sender.view as? KSClockHand, let beginPoint = beginPoints[handView] {
            let touchPoint = CGPoint(x: beginPoint.x*handView.touchScale, y: beginPoint.y*handView.touchScale)
            let point = CGPoint(x: touchPoint.x+translation.x, y: touchPoint.y+translation.y)
            var angle = atan(point.x/point.y)
            if (point.y < 0) {
                angle = CGFloat.pi-atan(point.x/abs(point.y))
            } else if (point.x < 0) {
                angle = 2*CGFloat.pi-atan(abs(point.x)/point.y)
            }
            
            // Update time
            if (handView == hourHand) {
                let hourOld = hour
                let dayminute = Int(Double(angle)*360/Double.pi)
                hour = dayminute/60
                if 11 <= abs(hourOld-hour) && abs(hourOld-hour) <= 13 {
                    hour += 12
                }
                minute = dayminute%60
            } else {
                let minuteOld = minute
                minute = Int(angle*30/CGFloat.pi)
                if abs(minute-minuteOld) > 50 {
                    if minute > minuteOld {
                        hour -= 1
                    } else {
                        hour += 1
                    }
                }
                if hour >= 24 {
                    hour -= 24
                } else if hour < 0 {
                    hour += 24
                }
            }
            // Update transform
            let (hourPoint, minutePoint) = updateTransform()
            if (sender.state == .ended) {
                beginPoints[hourHand] = hourPoint
                beginPoints[minuteHand] = minutePoint
                if let delegate = clockViewDelegate {
                    delegate.ksClockView(clockView: self, didUpdate: hour, minute: minute)
                }
            } else {
                if let delegate = clockViewDelegate {
                    delegate.ksClockView(clockView: self, updating: hour, minute: minute)
                }
            }
        }
    }
    
    func setTime(_ time: Date, animated: Bool = true) {
        hour = Calendar.current.component(.hour, from: time)
        minute = Calendar.current.component(.minute, from: time)
        if (animated) {
            UIView.animate(withDuration: 0.5) {
                let (hourPoint, minutePoint) = self.updateTransform()
                self.beginPoints = [self.minuteHand: minutePoint,
                                    self.hourHand: hourPoint]
            }
        } else {
            let (hourPoint, minutePoint) = self.updateTransform()
            self.beginPoints = [self.minuteHand: minutePoint,
                                self.hourHand: hourPoint]
        }
    }
    
}

class KSClockHand : UIView {
    
    var touchY: CGFloat = 0
    var touchScale: CGFloat = 0
    var long: CGFloat {
        get {
            return frame.height
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        touchY = long - location.y
        touchScale = touchY/long
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchY = 0
        touchScale = 0
    }
    
}
