//
// ViewController.swift
//
// Copyright (c) 2015 apploft. GmbH
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import ExpandableLabel

class ViewController: UITableViewController, ExpandableLabelDelegate {

    let numberOfCells : NSInteger = 12
    var states : Array<Bool>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        states = [Bool](repeating: true, count: numberOfCells)
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentSource = preparedSources()[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! ExpandableCell
        cell.expandableLabel.delegate = self
        
        cell.expandableLabel.setLessLinkWith(lessLink: "Close", attributes: [.foregroundColor:UIColor.red], position: currentSource.textAlignment)
        
        cell.layoutIfNeeded()
        
        cell.expandableLabel.shouldCollapse = true
        cell.expandableLabel.textReplacementType = currentSource.textReplacementType
        cell.expandableLabel.numberOfLines = currentSource.numberOfLines
        cell.expandableLabel.collapsed = states[indexPath.row]
        cell.expandableLabel.text = currentSource.text
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return states.count
    }
    
    func preparedSources() -> [(text: String, textReplacementType: ExpandableLabel.TextReplacementType, numberOfLines: Int, textAlignment: NSTextAlignment)] {
        return [(loremIpsumText(), .word, 3, .left),
                (textWithNewLinesInCollapsedLine(), .word, 2, .center),
                (textWithLongWordInCollapsedLine(), .character, 1, .right),
                (textWithVeryLongWords(), .character, 1, .left),
                (loremIpsumText(), .word, 4, .center),
                (loremIpsumText(), .character, 3, .right),
                (loremIpsumText(), .word, 2, .left),
                (loremIpsumText(), .character, 5, .center),
                (loremIpsumText(), .word, 3, .right),
                (loremIpsumText(), .character, 1, .left),
                (textWithShortWordsPerLine(), .character, 3, .center),
                (textEmojis(), .character, 3, .left)]
    }
    
    
    func loremIpsumText() -> String {
        return "On third line our text need be collapsed because we have ordinary text, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
    }
    
    func textWithNewLinesInCollapsedLine() -> String {
        return "When u had new line specialChars \n More not appeared eirmod\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n tempor invidunt ut\n\n\n\n labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
    }
    
    func textWithLongWordInCollapsedLine() -> String {
        return "When u had long word which not entered in one line More not appeared FooBaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaR tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
    }
    
    func textWithVeryLongWords() -> String {
        return "FooBaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaR FooBaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaR FooBaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaR FooBaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaR Will show first line and will increase touch area for more voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
    }
    
    func textWithShortWordsPerLine() -> String {
        return "A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM\nN"
    }
    
    func textEmojis() -> String {
        return "😂😄😃😊😍😗😜😅😓☺️😶🤦😒😁😟😵🙁🤔🤓☹️🙄😑😫😱🙂😧🤵😶👥👩‍❤️‍👩💖👨‍❤️‍💋‍👨💏👩‍👩‍👦‍👦👦👀👨‍👩‍👧‍👦👩‍❤️‍👩🗨🕴👩‍❤️‍💋‍👩👧☹️😠😤😆💚🙄🤒💋😿👄"
    }
    
    //
    // MARK: ExpandableLabel Delegate
    //
    
    func willExpandLabel(_ label: ExpandableLabel) {
        tableView.beginUpdates()
    }
    
    func didExpandLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) as IndexPath? {
            states[indexPath.row] = false
            DispatchQueue.main.async { [weak self] in
                self?.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
        tableView.endUpdates()
    }
    
    func willCollapseLabel(_ label: ExpandableLabel) {
        tableView.beginUpdates()
    }
    
    func didCollapseLabel(_ label: ExpandableLabel) {
        let point = label.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) as IndexPath? {
            states[indexPath.row] = true
            DispatchQueue.main.async { [weak self] in
                self?.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
        tableView.endUpdates()
    }
}

extension String {
    
    func specialPriceAttributedStringWith(_ color: UIColor) -> NSMutableAttributedString {
        let attributes = [NSAttributedString.Key.strikethroughStyle: NSNumber(value: NSUnderlineStyle.single.rawValue as Int),
                          .foregroundColor: color, .font: fontForPrice()]
        return NSMutableAttributedString(attributedString: NSAttributedString(string: self, attributes: attributes))
    }
    
    func priceAttributedStringWith(_ color: UIColor) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.foregroundColor: color, .font: fontForPrice()]
        
        return NSAttributedString(string: self, attributes: attributes)
    }
    
    func priceAttributedString(_ color: UIColor) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.foregroundColor: color]
        
        return NSAttributedString(string: self, attributes: attributes)
    }
    
    fileprivate func fontForPrice() -> UIFont {
        return UIFont(name: "Helvetica-Neue", size: 13) ?? UIFont()
    }
}



