//
//  ExpandableCell.swift
//  ExpandableLabelDemo
//
//  Created by Mathias Köhnke on 30/06/15.
//  Copyright (c) 2015 Mathias Koehnke. All rights reserved.
//

import UIKit

class ExpandableCell : UITableViewCell {
    
    
    @IBOutlet weak var expandableLabel: ExpandableLabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        expandableLabel.collapsed = true
        expandableLabel.text = nil
    }
}