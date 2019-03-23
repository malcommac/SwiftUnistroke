//
//  ViewController.swift
//  SwiftOneStroke
//
//  Created by Daniele Margutti on 02/10/15.
//  Copyright © 2015 danielemargutti. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private var loadedTemplates            :[SwiftUnistrokeTemplate] = []
    private var templateViews            :[StrokeView] = []
    @IBOutlet var drawView                :StrokeView!
    @IBOutlet var templatesScrollView    :UIScrollView!
    @IBOutlet var labelTemplates        :UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadTemplatesDirectory()
        
        drawView.backgroundColor = UIColor.cyan
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
                let (template,distance) = try strokeRecognizer.recognizeIn(templates: self.loadedTemplates, useProtractor:  false)
                
                var title: String = ""
                var message: String = ""
                if template != nil {
                    title = "Gesture Recognized!"
                    message = "Let me try...is it a \(template!.name.uppercased)?"
                    print("[FOUND] Template found is \(template!.name) with distance: \(distance!)")
                } else {
                    print("[FAILED] Template not found")
                    title = "Ops...!"
                    message = "I cannot recognize this gesture. So sad my dear..."
                }
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
                let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
                alert.addAction(okButton)
                self.present(alert, animated: true, completion: nil)
                
            } catch (let error as NSError) {
                print("[FAILED] Error: \(error.localizedDescription)")
                
                let alert = UIAlertController(title: "Ops, something wrong happened!", message: "\(error.localizedDescription)", preferredStyle: UIAlertController.Style.alert)
                let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
                alert.addAction(okButton)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func loadTemplatesDirectory() {
        do {
            // Load template files
            let templatesFolder = Bundle.main.resourcePath!.appendingFormat("/Templates")
            let list = try FileManager.default.contentsOfDirectory(atPath: templatesFolder)
            
            var x:CGFloat = 0.0
            let size = templatesScrollView.frame.height
            for file in list {
                let templateData = NSData(contentsOfFile: templatesFolder.appendingFormat("/%@", file))
                let templateDict = try JSONSerialization.jsonObject(with: templateData! as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
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
                let templateView = UIImageView(frame: CGRect(origin: CGPoint(x: x, y: 0), size: CGSize(width: size, height: size)))
                
                
                templateView.image = UIImage(named: templateImage)
                templateView.contentMode = UIView.ContentMode.scaleAspectFit
                templateView.layer.borderColor = UIColor.lightGray.cgColor
                templateView.layer.borderWidth = 2
                templatesScrollView.addSubview(templateView)
                x = templateView.frame.maxX+2
            }
            
            print("- \(loadedTemplates.count) templates are now loaded!")
            
            // setup scroll view size
            templatesScrollView.contentSize = CGSize(width: x+CGFloat(2*loadedTemplates.count), height: size)
            templatesScrollView.backgroundColor = UIColor.white
            labelTemplates.text = "\(loadedTemplates.count) TEMPLATES LOADED:"
        } catch (let error as NSError) {
            print("Something went wrong while loading templates: \(error.localizedDescription)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
}

