//
//  ExpandableLabel.swift
//  ExpandableLabelDemo
//
//  Created by Mathias Köhnke on 29/06/15.
//  Copyright (c) 2015 Mathias Koehnke. All rights reserved.
//

import UIKit


class ExpandableLabel : UILabel {
    
    var collapsedNumberOfLines : NSInteger = 3
    var collapsed : Bool = true {
        didSet {
            super.attributedText = (collapsed) ? self.collapsedText : self.expandedText
            super.numberOfLines = (collapsed) ? collapsedNumberOfLines : 0
        }
    }
    var collapsedAttributedLink : NSAttributedString? {
        get {
            return NSAttributedString(string: "More", attributes: [NSFontAttributeName : UIFont.boldSystemFontOfSize(font.pointSize), NSForegroundColorAttributeName : UIColor.redColor()])
        }
    }
    
    private var collapsedAttributedHighlightedLink : NSAttributedString? {
        get {
            var collapsedLinkHighlighted = NSMutableAttributedString()
            if let collapsedAttributedLink = collapsedAttributedLink {
                let range = NSMakeRange(0, collapsedAttributedLink.length)
                let alphaComponent = CGFloat(0.5)
                var baseColor: UIColor? = collapsedAttributedLink.attribute(NSForegroundColorAttributeName, atIndex: 0, effectiveRange: nil) as? UIColor
                if let color = baseColor { baseColor = color.colorWithAlphaComponent(alphaComponent) }
                else { baseColor = textColor.colorWithAlphaComponent(alphaComponent) }
                collapsedLinkHighlighted.appendAttributedString(collapsedAttributedLink)
                collapsedLinkHighlighted.removeAttribute(NSForegroundColorAttributeName, range: NSMakeRange(0, collapsedLinkHighlighted.length))
                collapsedLinkHighlighted.addAttribute(NSForegroundColorAttributeName, value: baseColor!, range: NSMakeRange(0, collapsedLinkHighlighted.length))
            }
            return collapsedLinkHighlighted
        }
    }
    
    private var linkHighlighted : Bool = false
    
    override var text: String? {
        set(text) {
            if let text = text {
                self.attributedText = NSAttributedString(string: text, attributes: [NSFontAttributeName : font])
            } else {
                self.attributedText = nil
            }
        }
        get {
            return self.attributedText?.string
        }
    }
    
    override var attributedText: NSAttributedString? {
        set(attributedText) {
            if let attributedText = attributedText {
                self.expandedText = attributedText
                self.collapsedText = getCollapsedTextForText(attributedText, link: (linkHighlighted) ? collapsedAttributedHighlightedLink : collapsedAttributedLink)
                super.attributedText = (self.collapsed) ? self.collapsedText : self.expandedText;
            } else {
                super.attributedText = nil
            }
        }
        get {
            return super.attributedText
        }
    }
    
    //
    // MARK: Private
    //
    
    private var expandedText : NSAttributedString?
    private var collapsedText : NSAttributedString?
    private var linkRect : CGRect?

    override func awakeFromNib() {
        super.awakeFromNib()
        userInteractionEnabled = true
    }
    
    private func getLinesArrayOfAttributedText(attributedText : NSAttributedString) -> Array<CTLineRef> {
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: frame.size.width, height: CGFloat(MAXFLOAT)))
        let frameSetterRef : CTFramesetterRef = CTFramesetterCreateWithAttributedString(attributedText as CFAttributedStringRef)
        let frameRef : CTFrameRef = CTFramesetterCreateFrame(frameSetterRef, CFRangeMake(0, 0), path.CGPath, nil)
        return CTFrameGetLines(frameRef) as! Array<CTLineRef>
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        attributedText = expandedText
    }
    
    private func textWithLinkReplacement(line : CTLineRef, lineText : NSAttributedString, linkName : NSAttributedString) -> NSAttributedString {
        let lineText = stringForLine(line, lineText: lineText)
        var lineTextWithLink = lineText
        (lineText.string as NSString).enumerateSubstringsInRange(NSMakeRange(0, lineText.length), options: .ByWords | .Reverse) { (word, subRange, enclosingRange, stop) -> () in
            let lineTextWithLastWordRemoved = lineText.attributedSubstringFromRange(NSMakeRange(0, subRange.location))
            let lineTextWithAddedLink = NSMutableAttributedString(attributedString: lineTextWithLastWordRemoved)
            lineTextWithAddedLink.appendAttributedString(NSAttributedString(string: "... "))
            lineTextWithAddedLink.appendAttributedString(linkName)
            let fits = self.textFitsWidth(lineTextWithAddedLink)
            if (fits == true) {
                lineTextWithLink = lineTextWithAddedLink
                let lineTextWithLastWordRemovedRect = self.rectOfText(lineTextWithLastWordRemoved)
                let wordRect = self.rectOfText(linkName)
                self.linkRect = CGRectMake(lineTextWithLastWordRemovedRect.size.width, self.font.lineHeight * CGFloat(self.collapsedNumberOfLines-1), wordRect.size.width, wordRect.size.height)
                stop.memory = true
            }
        }
        return lineTextWithLink
    }

    
    private func getCollapsedTextForText(text : NSAttributedString?, link: NSAttributedString?) -> NSAttributedString? {
        if let text = text {
            let lines = getLinesArrayOfAttributedText(text)
            if (collapsedNumberOfLines <= lines.count) {
                let lastLineRef = lines[collapsedNumberOfLines-1] as CTLineRef
                let modifiedLastLineText = textWithLinkReplacement(lastLineRef, lineText: text, linkName: link!)
                
                var collapsedLines = NSMutableAttributedString()
                if (collapsedNumberOfLines >= 2) {
                    for index in 0...collapsedNumberOfLines-2 {
                        collapsedLines.appendAttributedString(stringForLine(lines[index], lineText: text))
                    }
                }
                collapsedLines.appendAttributedString(modifiedLastLineText)
                return collapsedLines
            }
            return text
        } else {
            return nil;
        }
    }

    private func textFitsWidth(text : NSAttributedString) -> Bool {
        return (rectOfText(text).size.height <= font.lineHeight) as Bool
    }
    
    private func rectOfText(text : NSAttributedString) -> CGRect {
        return text.boundingRectWithSize(CGSize(width: self.frame.size.width, height: CGFloat(MAXFLOAT)),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
    }
    
    private func stringForLine(lineRef : CTLineRef, lineText : NSAttributedString) -> NSAttributedString {
        let lineRangeRef : CFRange = CTLineGetStringRange(lineRef)
        let range : NSRange = NSMakeRange(lineRangeRef.location, lineRangeRef.length)
        return lineText.attributedSubstringFromRange(range)
    }
    
    private func setLinkHighlighted(touches: Set<NSObject>, event: UIEvent, highlighted : Bool) -> Bool {
        let touch = event.allTouches()?.first as? UITouch
        let location = touch?.locationInView(self)
        if let linkRect = linkRect, location = location {
            if collapsed && CGRectContainsPoint(linkRect, location) {
                linkHighlighted = highlighted
                attributedText = expandedText
                setNeedsDisplay()
                return true
            }
        }
        return false
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        setLinkHighlighted(touches, event: event, highlighted: true)
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        setLinkHighlighted(touches, event: event, highlighted: false)
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        if setLinkHighlighted(touches, event: event, highlighted: false) {
            collapsed = false
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        setLinkHighlighted(touches, event: event, highlighted: false)
    }
}