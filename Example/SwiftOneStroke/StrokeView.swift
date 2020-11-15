//
//  StrokeView.swift
//  SwiftOneStroke
//
//  Created by Daniele Margutti on 04/10/15.
//  Copyright © 2015 danielemargutti. All rights reserved.
//

import UIKit

typealias StrokeViewEndBlock = (_ points: [StrokePoint]?) -> (Void)

public class StrokeView : UIView {
    
    var drawPath: UIBezierPath
    var onDidFinishDrawing: StrokeViewEndBlock?
    var activePoints = [StrokePoint]()
    
    override init(frame: CGRect) {
        drawPath = UIBezierPath()
        super.init(frame: frame)
        self.backgroundColor = UIColor.lightGray
    }
    
    required public init?(coder aDecoder: NSCoder) {
        drawPath = UIBezierPath()
        super.init(coder: aDecoder)
    }
    
    public func loadPath(points: [StrokePoint]) {
        self.drawPath = UIBezierPath()
        if points.count > 0 {
            self.drawPath.move(to: points.first!.toPoint())
            for i in 1..<points.count {
                self.drawPath.addLine(to: points[i].toPoint())
            }
            self.setNeedsDisplay()
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.drawPath = UIBezierPath()
        self.drawPath.lineWidth = 3.0
        
        activePoints.removeAll()
        
        let point = touches.first!.location(in: self)
        self.drawPath.move(to: point)
        activePoints.append(StrokePoint(point: point))
        
        self.setNeedsDisplay()
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self)
        self.drawPath.addLine(to: point)
        activePoints.append(StrokePoint(point: point))
        
        self.setNeedsDisplay()
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self)
        self.drawPath.move(to: point)
        activePoints.append(StrokePoint(point: point))
        self.setNeedsDisplay()
        onDidFinishDrawing?(activePoints)
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesEnded(touches, with: event)
    }
    
    public override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        
        ctx?.setLineWidth(3.0)
        ctx?.addPath(self.drawPath.cgPath)
        ctx?.strokePath()
    }
}
