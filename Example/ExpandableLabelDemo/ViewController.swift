//
//  ViewController.swift
//  ExpandableLabelDemo
//
//  Created by Mathias Köhnke on 29/06/15.
//  Copyright (c) 2015 Mathias Koehnke. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var expandableLabel: ExpandableLabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        expandableLabel.text = loremIpsumText()
        
    }
    
    func attributedString(text: String) -> NSAttributedString {
        return NSAttributedString(string: text)
    }
    
    @IBAction func expandButtonTouched(sender: AnyObject) {
        expandableLabel.collapsed = !expandableLabel.collapsed
    }
    
    
    func loremIpsumText() -> String {
        return "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
    }
}

