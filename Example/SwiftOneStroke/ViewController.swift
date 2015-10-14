//
//  ViewController.swift
//  SwiftOneStroke
//
//  Created by Daniele Margutti on 02/10/15.
//  Copyright © 2015 danielemargutti. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	private var loadedTemplates			:[SwiftUnistrokeTemplate] = []
	private var templateViews			:[StrokeView] = []
	@IBOutlet var drawView				:StrokeView!
	@IBOutlet var templatesScrollView	:UIScrollView!
	@IBOutlet var labelTemplates		:UILabel!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		loadTemplatesDirectory()
		
		drawView.backgroundColor = UIColor.cyanColor()
		// we set a completion handler called on touchesCancelled/End which
		// grab drawn points and pass them to the one stroke recognizer class
		drawView.onDidFinishDrawing = { drawnPoints in
			if drawnPoints == nil {
				return
			}
			
			if drawnPoints!.count < 5 {
				return
			}
			
			let strokeRecognizer = SwiftUnistroke(points: drawnPoints!)
			do {
				let (template,distance) = try strokeRecognizer.recognizeIn(self.loadedTemplates, useProtractor:  false)
				
				var title: String = ""
				var message: String = ""
				if template != nil {
					title = "Gesture Recognized!"
					message = "Let me try...is it a \(template!.name.uppercaseString)?"
					print("[FOUND] Template found is \(template!.name) with distance: \(distance!)")
				} else {
					print("[FAILED] Template not found")
					title = "Ops...!"
					message = "I cannot recognize this gesture. So sad my dear..."
				}
				
				let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
				let okButton = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
				alert.addAction(okButton)
				self.presentViewController(alert, animated: true, completion: nil)

			} catch (let error as NSError) {
				print("[FAILED] Error: \(error.localizedDescription)")
				
				let alert = UIAlertController(title: "Ops, something wrong happened!", message: "\(error.localizedDescription)", preferredStyle: UIAlertControllerStyle.Alert)
				let okButton = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
				alert.addAction(okButton)
				self.presentViewController(alert, animated: true, completion: nil)
			}
		}
	}
	
	private func loadTemplatesDirectory() {
		do {
			// Load template files
			let templatesFolder = NSBundle.mainBundle().resourcePath!.stringByAppendingString("/Templates")
			let list = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(templatesFolder)
			
			var x:CGFloat = 0.0
			let size = CGRectGetHeight(templatesScrollView.frame)
			for file in list {
				let templateData = NSData(contentsOfFile: templatesFolder.stringByAppendingFormat("/%@", file))
				let templateDict = try NSJSONSerialization.JSONObjectWithData(templateData!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
				let templateName = templateDict["name"]! as! String
				let templateImage = templateDict["image"]! as! String
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
				
				// For each template get its preview and show them inside the bottom screen scroll view
				let templateView = UIImageView(frame: CGRectMake(x,0,size,size))
				templateView.image = UIImage(named: templateImage)
				templateView.contentMode = UIViewContentMode.ScaleAspectFit
				templateView.layer.borderColor = UIColor.lightGrayColor().CGColor
				templateView.layer.borderWidth = 2
				templatesScrollView.addSubview(templateView)
				x = CGRectGetMaxX(templateView.frame)+2
			}
			
			print("- \(loadedTemplates.count) templates are now loaded!")
			
			// setup scroll view size
			templatesScrollView.contentSize = CGSizeMake(x+CGFloat(2*loadedTemplates.count), size)
			templatesScrollView.backgroundColor = UIColor.whiteColor()
			labelTemplates.text = "\(loadedTemplates.count) TEMPLATES LOADED:"
		} catch (let error as NSError) {
			print("Something went wrong while loading templates: \(error.localizedDescription)")
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


}

