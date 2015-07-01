//
//  ViewController.swift
//  ExpandableLabelDemo
//
//  Created by Mathias Köhnke on 29/06/15.
//  Copyright (c) 2015 Mathias Koehnke. All rights reserved.
//

import UIKit

class ViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, ExpandableLabelDelegate {

    let numberOfCells : NSInteger = 10
    var states : Array<Bool>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        states = [Bool](count: numberOfCells, repeatedValue: true)
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! ExpandableCell
        cell.expandableLabel.delegate = self
        cell.expandableLabel.numberOfLines = 3
        cell.expandableLabel.collapsed = states[indexPath.row]
        cell.expandableLabel.text = loremIpsumText()
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfCells
    }
    
    
    func loremIpsumText() -> String {
        return "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
    }
    
    //
    // MARK: ExpandableLabel Delegate
    //
    
    func willExpandLabel(label: ExpandableLabel) {
        tableView.beginUpdates()
    }
    
    func didExpandLabel(label: ExpandableLabel) {
        let point = label.convertPoint(CGPointZero, toView: tableView)
        if let indexPath = tableView.indexPathForRowAtPoint(point) as NSIndexPath? {
            states[indexPath.row] = false
        }
        tableView.endUpdates()
    }
}


