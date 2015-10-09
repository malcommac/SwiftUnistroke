//
//  StrokeView.swift
//  SwiftOneStroke
//
//  Created by daniele on 04/10/15.
//  Copyright © 2015 danielemargutti. All rights reserved.
//

import UIKit

typealias StrokeViewEndBlock = (points: [StrokePoint]?) -> (Void)

public class StrokeView : UIView {
	
	var drawPath: UIBezierPath
	var onDidFinishDrawing: StrokeViewEndBlock?
	var activePoints = [StrokePoint]()
	
	override init(frame: CGRect) {
		drawPath = UIBezierPath()
		super.init(frame: frame)
		self.backgroundColor = UIColor.lightGrayColor()
	}

	required public init?(coder aDecoder: NSCoder) {
		drawPath = UIBezierPath()
		super.init(coder: aDecoder)
	}
	
	public func loadPath(points: [StrokePoint]) {
		self.drawPath = UIBezierPath()
		if points.count > 0 {
			self.drawPath.moveToPoint(points.first!.toPoint())
			for (var i = 1; i < points.count; ++i) {
				self.drawPath.addLineToPoint(points[i].toPoint())
			}
			self.setNeedsDisplay()
		}
	}
	
	public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		self.drawPath = UIBezierPath()
		self.drawPath.lineWidth = 3.0
		
		activePoints.removeAll()

		let point = touches.first!.locationInView(self)
		self.drawPath.moveToPoint(point)
		activePoints.append(StrokePoint(point: point))
		
		self.setNeedsDisplay()
	}
	
	public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		let point = touches.first!.locationInView(self)
		self.drawPath.addLineToPoint(point)
		activePoints.append(StrokePoint(point: point))

		self.setNeedsDisplay()
	}
	
	public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		let point = touches.first!.locationInView(self)
		self.drawPath.moveToPoint(point)
		activePoints.append(StrokePoint(point: point))
		self.setNeedsDisplay()
		onDidFinishDrawing?(points: activePoints)
	}
	
	public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
		if touches != nil {
			self.touchesEnded(touches!, withEvent: event)
		}
	}

	public override func drawRect(rect: CGRect) {
		let ctx = UIGraphicsGetCurrentContext()
		CGContextSetLineWidth(ctx, 3.0)
		CGContextAddPath(ctx, self.drawPath.CGPath)
		CGContextStrokePath(ctx)
	}
}