//
//  ViewController.swift
//  SwiftOneStroke
//
//  Created by daniele on 02/10/15.
//  Copyright © 2015 danielemargutti. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	private var loadedTemplates : [SwiftUnistrokeTemplate] = []
	private var templateViews: [StrokeView] = []
	@IBOutlet var drawView: StrokeView!
	@IBOutlet var templatesScrollView: UIScrollView!
	@IBOutlet var labelTemplates: UILabel!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		loadTemplatesDirectory()
		
		drawView.backgroundColor = UIColor.lightGrayColor()
		drawView.onDidFinishDrawing = { drawnPoints in
			if drawnPoints == nil {
				return
			}
			
			let strokeRecognizer = SwiftUnistroke(points: drawnPoints!)
			do {
				let (template,distance) = try strokeRecognizer.recognizeIn(self.loadedTemplates, useProtractor:  false)
				if template != nil {
					print("[FOUND] Template found is \(template!.name) with distance: \(distance!)")
				} else {
					print("[FAILED] Template not found")
				}
			} catch (let error as NSError) {
				print("[FAILED] Error: \(error.localizedDescription)")
			}
		}
	}
	
	private func loadTemplatesDirectory() {
		do {
			let templatesFolder = NSBundle.mainBundle().resourcePath!.stringByAppendingString("/Templates")
			let list = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(templatesFolder)
			
			var x:CGFloat = 0.0
			let size = CGRectGetHeight(templatesScrollView.frame)
			for file in list {
				let templateData = NSData(contentsOfFile: templatesFolder.stringByAppendingFormat("/%@", file))
				let templateDict = try NSJSONSerialization.JSONObjectWithData(templateData!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
				let templateName = templateDict["name"]! as! String
				let templateRawPoints: [AnyObject] = templateDict["points"]! as! [AnyObject]
				var templatePoints: [StrokePoint] = []
				for rawPoint in templateRawPoints {
					let x = (rawPoint as! [AnyObject]).first! as! Double
					let y = (rawPoint as! [AnyObject]).last! as! Double
					templatePoints.append(StrokePoint(x: x, y: y))
				}
				
				let templateObj = SwiftUnistrokeTemplate(name: templateName, points: templatePoints)
				loadedTemplates.append(templateObj)
				print("  - Loaded template '\(templateName)' with \(templateObj.points.count) points inside")
				
				let templateView = StrokeView(frame: CGRectMake(x,0,size,size))
				let scaled = StrokePoint.translate(StrokePoint.scale(templateObj.points, toSize: Double(size)), to: StrokePoint(point: CGPointZero))
				templateView.loadPath(scaled)
				templatesScrollView.addSubview(templateView)
				x = CGRectGetMaxX(templateView.frame)+2
			}
			print("- \(loadedTemplates.count) templates are now loaded!")
			templatesScrollView.contentSize = CGSizeMake(x+CGFloat(2*loadedTemplates.count), size)
			templatesScrollView.backgroundColor = UIColor.whiteColor()
			labelTemplates.text = "\(loadedTemplates.count) AVAILABLE TEMPLATES"
		} catch (let error as NSError) {
			print("Something went wrong while loading templates: \(error.localizedDescription)")
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

