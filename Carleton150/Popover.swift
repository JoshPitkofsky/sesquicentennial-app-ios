//
//  Popover.swift
//  Carleton150
//
//  Created by Sherry Gu on 1/26/16.
//  Copyright © 2016 edu.carleton.carleton150. All rights reserved.
//

import Foundation
import UIKit
class Popover: UIViewController, UIPopoverPresentationControllerDelegate{
    var nameText: String = "name"
    var descriptionText: String = "description"
    
    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var Back: UIButton!
    
    @IBAction func triggered(sender: AnyObject) {
        self.performSegueWithIdentifier("mapView", sender: nil)
    }
    
    @IBOutlet weak var Content: UILabel!
    @IBOutlet weak var Timeline: UILabel!
    func setTextFields() {
        self.Content.text = nameText
        self.Timeline.text = descriptionText
    }
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.FullScreen
    }
    
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let navigationController = UINavigationController(rootViewController: controller.presentedViewController)
        let btnDone = UIBarButtonItem(title: "Done", style: .Done, target: self, action: "dismiss")
        navigationController.topViewController!.navigationItem.rightBarButtonItem = btnDone
        return navigationController
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    override func viewDidLoad() {
        self.setTextFields()
    }

}