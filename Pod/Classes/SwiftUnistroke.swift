//
//  SwiftOneStroke.swift
//  SwiftOneStroke
//	=======================================
//
//	$1 Unistroke Implementation in Swift 2+
//
//  Created by Daniele Margutti on 02/10/15.
//	Copyright (c) 2015 Daniele Margutti. All Rights Reserved.
//	This code is distribuited under MIT license (https://en.wikipedia.org/wiki/MIT_License).
//
//	Daniele Margutti
//	Web:			http://www.danielemargutti.com
//	Mail:			hello@danielemargutti.com
//	Twitter:		@danielemargutti
//
//	Original algorithm was developed by:
//
//  Jacob Wobbrock, Andy Wilson, Yang Li
//	"Gestures without libraries, toolkits or Training: a $1.00 Recognizer for User Interface Prototypes"
//	ACM Symposium on User Interface Software and Technology (2007)
//	(p.159-168).
//	Web: https://depts.washington.edu/aimgroup/proj/dollar/
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

import Foundation
import UIKit
import Darwin


/**
Exceptions

- MatchNotFound:  No valid matches found for recognize method
- EmptyTemplates: No templates array provided
- TooFewPoints:   Too few points for input path points
*/
public enum StrokeErrors: ErrorType {
	case MatchNotFound
	case EmptyTemplates
	case TooFewPoints
}

public class SwiftUnistroke {
	var points: [StrokePoint] = []
	
	
	/**
	Initialize a new recognizer class.
	
	- parameter points: Input points array
	
	- returns: the instance of the recognizer
	*/
	public init(points: [StrokePoint]) {
		self.points = points
	}
	
	/**
	This method initiate the recognition task. Based upon passed templates it return the best score found or throws an exception if fails.
	You can also execute this method in another thread.
	
	- parameter templates:     an arrat of SwiftUnistrokeTemplate objects
	- parameter useProtractor: use protractor method to compare angles (faster but less accurate)
	- parameter minThreshold:  minimum accepted threshold to return found match (a value between 0 and 1; a 0.80 threshold is the default choice)
	
	- throws: throws an exception if templates aray is empty, passed input stroke points are not enough or match is not found.
	
	- returns: best match
	*/
	public func recognizeIn(templates: [SwiftUnistrokeTemplate]!, useProtractor: Bool = false, minThreshold: Double = 0.80) throws -> (template: SwiftUnistrokeTemplate?, distance: Double?) {
		if templates.count == 0 || points.count == 0 {
			throw StrokeErrors.EmptyTemplates
		}
		if points.count < 10 {
			throw StrokeErrors.TooFewPoints
		}
		self.points = StrokePoint.resample(points, totalPoints: StrokeConsts.numPoints)
		let radians = StrokePoint.indicativeAngle(self.points)
		self.points = StrokePoint.rotate(self.points, byRadians: -radians)
		self.points = StrokePoint.scale(self.points, toSize: StrokeConsts.squareSize)
		self.points = StrokePoint.translate(self.points, to: StrokePoint.zeroPoint())
		let vector = StrokePoint.vectorize(self.points)
		
		var bestDistance = Double.infinity
		var bestTemplate: SwiftUnistrokeTemplate?
		for template in templates {
			var templateDistance: Double
			if useProtractor == true {
				templateDistance = StrokePoint.optimalCosineDistance(template.vector, v2: vector)
			} else {
				templateDistance = StrokePoint.distanceAtBestAngle(points, strokeTemplate: template.points, fromAngle:  -StrokeConsts.angleRange, toAngle: StrokeConsts.angleRange, threshold: StrokeConsts.anglePrecision)
			}
			if templateDistance < bestDistance {
				bestDistance = templateDistance
				bestTemplate = template
			}
		}
		
		if bestTemplate != nil {
			bestDistance = (useProtractor == true ? 1.0 / bestDistance : 1.0 - bestDistance / StrokeConsts.halfDiagonal)
			if bestDistance < minThreshold {
				throw StrokeErrors.MatchNotFound
			}
			return (bestTemplate,bestDistance)
		} else {
			throw StrokeErrors.MatchNotFound
		}
	}
	
}


/// This class represent a stroke template. You pass a list of these objects to the the recognizer in order to perform a search
/// You can allocate a new template starting from a list of CGPoints or StrokePoints (a variant of CGPoint which is more precise)
public class SwiftUnistrokeTemplate : SwiftUnistroke {
	var name: String
	var vector: [Double]
	
	/**
	Initialize a new template object with a name and a list of stroke points
	
	- parameter name:   name of the template
	- parameter points: list of points (must be a StrokePoint). Use convenince init to init from a list of CGPoint (ie. when
						you have points taken from touches inside an UIView subclass.
	
	- returns: a stroke template instance
	*/
	public init(name: String, points: [StrokePoint]) {
		self.name = name
		var initializedPoints = StrokePoint.resample(points, totalPoints: StrokeConsts.numPoints)
		print(initializedPoints)
		let radians = StrokePoint.indicativeAngle(initializedPoints)
		initializedPoints = StrokePoint.rotate(initializedPoints, byRadians: -radians)
		initializedPoints = StrokePoint.scale(initializedPoints, toSize: StrokeConsts.squareSize)
		initializedPoints = StrokePoint.translate(initializedPoints, to: StrokePoint.zeroPoint())
		self.vector = StrokePoint.vectorize(initializedPoints)
		super.init(points: initializedPoints)
	}
	
	
	/**
	Initialize a new template object by passing a list of CGPoints
	
	- parameter name:   name of the template
	- parameter points: points array as CGPoint
	
	- returns: a stroke template instance
	*/
	public convenience init(name: String, points: [CGPoint]) {
		let strokePoints = StrokePoint.pointsArray(fromCGPoints: points)
		self.init(name: name, points: strokePoints)
	}
}

/**
*  StrokePoint is a class which represent a point, more or less is similar to CGPoint but uses double instead of float in order
*  to get a better precision.
*/
public struct StrokePoint {
	var x: Double
	var y: Double
	
	/**
	Initialize a new StrokePoint with passed pair of coordinates (x,y)
	
	- parameter x: x coordinate value
	- parameter y: y coordinate value
	
	- returns: a new StrokePoint
	*/
	public init(x: Double, y: Double) {
		self.x = x
		self.y = y
	}
	
	/**
	Initialize a new StrokePoint starting from a CGPoint
	
	- parameter point: source CGPoint
	
	- returns: strokePoint
	*/
	public init(point: CGPoint) {
		self.x = Double(point.x)
		self.y = Double(point.y)
	}
	
	/**
	Convert a StrokePoint to CGPoint
	
	- returns: CGPoint version of the object
	*/
	public func toPoint() -> CGPoint {
		return CGPointMake(CGFloat(self.x), CGFloat(self.y))
	}
	
	/**
	An origin stroke point (something like CGPointZero)
	
	- returns: An origin based StrokePoint
	*/
	public static func zeroPoint() -> StrokePoint {
		return StrokePoint(point: CGPointZero)
	}
	
	/**
	Get an array of StrokePoints starting from an array of CGPoints
	
	- parameter cgPoints: CGPoint array
	
	- returns: a StrokePoint array
	*/
	public static func pointsArray(fromCGPoints cgPoints: [CGPoint]) -> [StrokePoint] {
		var strokePoints: [StrokePoint] = []
		for point in cgPoints {
			strokePoints.append(StrokePoint(x: Double(point.x), y: Double(point.y)))
		}
		return strokePoints
	}
	
}

/**
*  This class is the CGRect variant based upon double data type
*/
public struct BoundingRect {
	var x: Double
	var y: Double
	var width: Double
	var height: Double
	
	public init(x: Double, y: Double, w: Double, h: Double) {
		self.x = x
		self.y = y
		self.width = w
		self.height = h
	}
}

/**
*  A list of constants used inside the Stroke Recognizer algorithm
*/
public struct StrokeConsts {
	public static let Phi: Double = (0.5 * (-1.0 + sqrt(5.0)))
	public static let numPoints: Int = 64
	public static let squareSize: Double = 250.0
	public static let diagonal = sqrt( squareSize * squareSize + squareSize * squareSize )
	public static let halfDiagonal = (diagonal * 0.5)
	public static let angleRange: Double = Double(45.0).toRadians()
	public static let anglePrecision: Double = Double(2.0).toRadians()
}

/**
*  This class represent a mutable edge (rect) instance.
*/
public struct Edge {
	private var minX: Double
	private var minY: Double
	private var maxX: Double
	private var maxY: Double
	
	/**
	Initialize a new edges rect with passed minX,maxX,minY,maxY values
	
	- parameter minX: min x
	- parameter maxX: max x
	- parameter minY: min y
	- parameter maxY: max y
	
	- returns: a new rect edges structure
	*/
	init(minX: Double, maxX: Double, minY: Double, maxY: Double) {
		self.minX = minX
		self.minY = minY
		self.maxX = maxX
		self.maxY = maxY
	}
	
	/**
	Add a new point to the edge. Each point growth the size of the edge rect
	
	- parameter value: value to cumulate
	*/
	public mutating func addPoint(value: StrokePoint) {
		self.minX = min(self.minX,value.x)
		self.maxX = max(self.maxX,value.x)
		self.minY = min(self.minY,value.y)
		self.maxY = max(self.maxY,value.y)
	}

}

extension Double {
	
	/**
	Convert a degree value to radians
	
	- returns: radian
	*/
	public func toRadians() -> Double {
		let res = self * M_PI / 180.0
		return res
	}
	
}

extension StrokePoint {
	
	/**
	Return the lenght of a path points
	
	- parameter points: array of points
	
	- returns: length of the segment
	*/
	public static func pathLength(points: [StrokePoint]) -> Double {
		var totalDistance:Double = 0.0
		for var idx = 1; idx < points.count; ++idx {
			totalDistance += points[idx-1].distanceTo(points[idx])
		}
		return totalDistance
	}
	
	/**
	Return the distance between two paths
	
	- parameter path1: path 1
	- parameter path2: path 2
	
	- returns: distance
	*/
	public static func pathDistance(path1: [StrokePoint], path2: [StrokePoint]) -> Double {
		var d: Double = 0.0
		for (var idx = 0; idx < path1.count; ++idx) {
			d += path1[idx].distanceTo(path2[idx])
		}
		return (d / Double(path1.count))
	}
	
	/**
	Return the centroid of a path points
	
	- parameter points: path
	
	- returns: centroid point
	*/
	public static func centroid(points: [StrokePoint]) -> StrokePoint {
		var centroidPoint = StrokePoint.zeroPoint()
		for point in points {
			centroidPoint.x = centroidPoint.x + point.x
			centroidPoint.y = centroidPoint.y + point.y
		}
		let totalPoints = Double(points.count)
		centroidPoint.x = (centroidPoint.x / totalPoints)
		centroidPoint.y = (centroidPoint.y / totalPoints)
		return centroidPoint
	}
	
	/**
	Return the bounding rect which contains a set of points
	
	- parameter points: points array
	
	- returns: the rect (as BoundingRect) which contains all the points
	*/
	public static func boundingBox(points: [StrokePoint]) -> BoundingRect {
		var edge = Edge(minX: +Double.infinity, maxX: -Double.infinity, minY: +Double.infinity, maxY: -Double.infinity)
		for point in points {
			edge.addPoint(point)
		}
		let rect = BoundingRect(x: edge.minX, y: edge.minY, w: (edge.maxX - edge.minX), h: (edge.maxY - edge.minY) )
		return rect
	}
	
	/**
	Return the distance of a point (self) from another point
	
	- parameter point: target point
	
	- returns: distance
	*/
	public func distanceTo(point: StrokePoint) -> Double {
		let dx = point.x - self.x
		let dy = point.y - self.y
		return sqrt( dx * dx + dy * dy )
	}
	
	/**
	Rotate a path by given radians value and return the new set of paths
	
	- parameter points:  origin points array
	- parameter radians: rotation radians
	
	- returns: rotated points path
	*/
	public static func rotate(points: [StrokePoint], byRadians radians: Double) -> [StrokePoint] {
		let centroid = StrokePoint.centroid(points)
		let cosvalue = cos(radians)
		let sinvalue = sin(radians)
		var newPoints: [StrokePoint] = []
		for point in points {
			let qx = (point.x - centroid.x) * cosvalue - (point.y - centroid.y) * sinvalue + centroid.x
			let qy = (point.x - centroid.x) * sinvalue + (point.y - centroid.y) * cosvalue + centroid.y
			newPoints.append(StrokePoint(x: qx, y: qy))
		}
		return newPoints
	}
	
	/**
	Perform a non-uniform scale of given path points
	
	- parameter points: origin path points
	- parameter size:   new size
	
	- returns: scaled path points
	*/
	public static func scale(points: [StrokePoint], toSize size: Double) -> [StrokePoint] {
		let boundingBox = StrokePoint.boundingBox(points)
		var newPoints: [StrokePoint] = []
		for point in points {
			let qx = point.x * (size / boundingBox.width)
			let qy = point.y * (size / boundingBox.height)
			newPoints.append(StrokePoint(x: qx, y: qy))
		}
		return newPoints
	}

	/**
	Translate a set of path points by a given value expressed both for x and y coordinates
	
	- parameter points: path points
	- parameter pt:     translation point
	
	- returns: translated path points
	*/
	public static func translate(points: [StrokePoint], to pt: StrokePoint) -> [StrokePoint] {
		let centroidPoint = StrokePoint.centroid(points)
		var newPoints: [StrokePoint] = []
		for point in points {
			let qx = point.x + pt.x - centroidPoint.x
			let qy = point.y + pt.y - centroidPoint.y
			newPoints.append(StrokePoint(x: qx, y: qy))
		}
		return newPoints
	}
	
	/**
	Generate a vector representation for the gesture. The procedure takes two parameters: points are resampled points from Step 1, and oSensitive specifies whether the gesture should be treated orientation sensitive or invariant.
	The procedure first translates the gesture so that its centroid is the origin, and then rotates the gesture to align its indicative angle with a base orientation. VECTORIZE returns a normalized vector with a length of 2n.
	
	- parameter points: points
	
	- returns: a vector array of doubles
	*/
	public static func vectorize(points: [StrokePoint]) -> [Double] {
		var sum: Double = 0.0
		var vector: [Double] = []
		for point in points {
			vector.append(point.x)
			vector.append(point.y)
			sum += (point.x * point.x) + (point.y * point.y)
		}
		let magnitude = sqrt(sum)
		for (var i = 0; i < vector.count; ++i) {
			vector[i] = vector[i] / magnitude
		}
		return vector
	}
	
	/**
	This method return the optimal cosine distance; provides a closed-form solution to find the minimum cosine distance between the
	vectors of a template and the unknown gesture by only rotating the template once.
	More on protactor: https://depts.washington.edu/aimgroup/proj/dollar/protractor.pdf
	
	- parameter v1: vector 1
	- parameter v2: vector 2
	
	- returns: minimum cosine distance between two vectors
	*/
	public static func optimalCosineDistance(v1: [Double], v2: [Double]) -> Double {
		var a: Double = 0.0
		var b: Double = 0.0
		for (var i = 0; i < v1.count; i+=2) {
			a += v1[i] * v2[i] + v1[i+1] * v2[i+1]
			b += v1[i] * v2[i+1] - v1[i+1] * v2[i]
		}
		let angle = atan(b / a)
		let res = acos(a * cos(angle) + b * sin(angle))
		return res
	}
	
	
	/**
	Return the distance at best angle between two path points
	
	- parameter points:         input path points
	- parameter strokeTemplate: comparisor template path points
	- parameter fromAngle:      min angle
	- parameter toAngle:        max angle
	- parameter threshold:      accepted threshold
	
	- returns: min distance
	*/
	public static func distanceAtBestAngle(points: [StrokePoint], strokeTemplate: [StrokePoint], var fromAngle: Double, var toAngle: Double, threshold: Double) -> Double {
		var x1 = StrokeConsts.Phi * fromAngle + (1.0 - StrokeConsts.Phi) * toAngle
		var f1 = StrokePoint.distanceAtAngle(points, strokeTemplate: strokeTemplate, radians: x1)
		
		var x2 = (1.0 - StrokeConsts.Phi) * fromAngle + StrokeConsts.Phi * toAngle
		var f2 = StrokePoint.distanceAtAngle(points, strokeTemplate: strokeTemplate, radians: x2)
		
		while ( abs(toAngle-fromAngle) > threshold ) {
			if f1 < f2 {
				toAngle = x2
				x2 = x1
				f2 = f1
				x1 = StrokeConsts.Phi * fromAngle + (1.0 - StrokeConsts.Phi) * toAngle
				f1 = StrokePoint.distanceAtAngle(points, strokeTemplate: strokeTemplate, radians: x1)
			} else {
				fromAngle = x1
				x1 = x2
				f1 = f2
				x2 = (1.0 - StrokeConsts.Phi) * fromAngle + StrokeConsts.Phi * toAngle
				f2 = StrokePoint.distanceAtAngle(points, strokeTemplate: strokeTemplate, radians: x2)
			}
		}
		return min(f1,f2)
	}
	
	/**
	Distance of a path points with another one at given angle
	
	- parameter points:         input path points
	- parameter strokeTemplate: comparisor template path points
	- parameter radians:        value of the angle
	
	- returns: distance at given angle between path points
	*/
	public static func distanceAtAngle(points: [StrokePoint], strokeTemplate: [StrokePoint], radians: Double) -> Double {
		let newPoints = StrokePoint.rotate(points, byRadians: radians)
		return StrokePoint.pathDistance(newPoints, path2: strokeTemplate)
	}
	
	/**
	Return indicative angle for a given set of path points
	
	- parameter points: points
	
	- returns: rotation indicative angle of the path
	*/
	public static func indicativeAngle(points: [StrokePoint]) -> Double {
		let centroid = StrokePoint.centroid(points)
		return atan2(centroid.y - points.first!.y, centroid.x - points.first!.x)
	}
	
	/**
	Resample the points of a gesture into n evenly spaced points. Protractor uses the same resampling method as the $1 recognizer3 does, although Protractor only needs n = 16 points to perform optimally.
	
	- parameter points:      path points array
	- parameter totalPoints: number of points of the output resampled points array
	
	- returns: resampled points array
	*/
	private static func resample(points: [StrokePoint], totalPoints: Int) -> [StrokePoint] {
		var initialPoints = points
		let interval = StrokePoint.pathLength(initialPoints) / Double(totalPoints - 1)
		var totalLength: Double = 0.0
		var newPoints: [StrokePoint] = [points.first!]
		for var i = 1; i < initialPoints.count; ++i {
			let currentLength = initialPoints[i-1].distanceTo(initialPoints[i])
			if ( (totalLength+currentLength) >= interval) {
				let qx = initialPoints[i-1].x + ((interval - totalLength) / currentLength) * (initialPoints[i].x - initialPoints[i-1].x)
				let qy = initialPoints[i-1].y + ((interval - totalLength) / currentLength) * (initialPoints[i].y - initialPoints[i-1].y)
				let q = StrokePoint(x: qx, y: qy)
				newPoints.append(q)
				initialPoints.insert(q, atIndex: i)
				totalLength = 0.0
			} else {
				totalLength += currentLength
			}
		}
		if newPoints.count == totalPoints-1 {
			newPoints.append(points.last!)
		}
		return newPoints
	}
}