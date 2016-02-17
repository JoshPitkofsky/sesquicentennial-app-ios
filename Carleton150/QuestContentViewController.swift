//
//  QuestContentViewController.swift
//  Carleton150
//
//  Created by Ibrahim Rabbani on 2/17/16.
//  Copyright © 2016 edu.carleton.carleton150. All rights reserved.
//

import UIKit

class QuestContentViewController: UIViewController {

	var pageIndex: Int!
	
	var titleText: String!
	var image: String!
	var descText: String!
	var buttonText: String!
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var descTextView: UITextView!
	@IBOutlet weak var startButton: UIButton!
	@IBOutlet weak var imageView: UIImageView!
	
    override func viewDidLoad() {
		
//		Utils.setUpNavigationBar(self)
		
		// Quest Name
		if let titleText = titleText {
			self.nameLabel.text = titleText
		} else {
			self.nameLabel.text = ""
		}
		// Quest Description
		if let descText = descText {
			self.descTextView.text = descText
		} else {
			self.descTextView.text = ""
		}
		self.descTextView.editable = false
		// Quest Image
		if let image = self.image {
			self.imageView.image = UIImage(data: NSData(base64EncodedString: image, options: .IgnoreUnknownCharacters)!)
		} else {
			// this will do something
		}
		
    }

	@IBAction func startAction(sender: AnyObject) {
	}
	
}
