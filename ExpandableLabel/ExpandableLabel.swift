//
//  ExpandableLabel.swift
//  ExpandableLabelDemo
//
//  Created by Mathias Köhnke on 29/06/15.
//  Copyright (c) 2015 Mathias Koehnke. All rights reserved.
//

import UIKit

/**
* The delegate of ExpandableLabel.
*/
protocol ExpandableLabelDelegate : class {
    func willExpandLabel(label: ExpandableLabel)
    func didExpandLabel(label: ExpandableLabel)
}

/**
 * ExpandableLabel
 */
class ExpandableLabel : UILabel {
    
    /// The delegate of ExpandableLabel
    weak var delegate: ExpandableLabelDelegate?
    
    /// Set 'true' if the label should be collapsed or 'false' for expanded.
    @IBInspectable var collapsed : Bool = true {
        didSet {
            super.attributedText = (collapsed) ? self.collapsedText : self.expandedText
            super.numberOfLines = (collapsed) ? self.collapsedNumberOfLines : 0
        }
    }
    
    /// Set the link name (and attributes) that is shown when collapsed.
    /// The default value is "More". Cannot be nil.
    @IBInspectable var collapsedAttributedLink : NSAttributedString!
    
    /// Set the ellipsis that appears just after the text and before the link.
    /// The default value is "...". Can be nil.
    var ellipsis : NSAttributedString?
    
    
    //
    // MARK: Private
    //
    
    private var expandedText : NSAttributedString?
    private var collapsedText : NSAttributedString?
    private var linkHighlighted : Bool = false
    private let touchSize = CGSize(width: 44, height: 44)
    private var linkRect : CGRect?
    private var collapsedNumberOfLines : NSInteger = 0
    
    override var numberOfLines: NSInteger {
        didSet {
            collapsedNumberOfLines = numberOfLines
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userInteractionEnabled = true
        lineBreakMode = NSLineBreakMode.ByClipping
        numberOfLines = 3
        collapsedAttributedLink = NSAttributedString(string: "More", attributes: [NSFontAttributeName : UIFont.boldSystemFontOfSize(font.pointSize)])
        ellipsis = NSAttributedString(string: "...", attributes: [NSFontAttributeName : font])
    }
    
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
            var lineTextWithAddedLink = NSMutableAttributedString(attributedString: lineTextWithLastWordRemoved)
            if let ellipsis = self.ellipsis {
                lineTextWithAddedLink.appendAttributedString(ellipsis)
                lineTextWithAddedLink.appendAttributedString(NSAttributedString(string: " ", attributes: [NSFontAttributeName : self.font]))
            }
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

    
    private func getCollapsedTextForText(text : NSAttributedString?, link: NSAttributedString) -> NSAttributedString? {
        if let text = text {
            let lines = getLinesArrayOfAttributedText(text)
            if (collapsedNumberOfLines > 0 && collapsedNumberOfLines < lines.count) {
                let lastLineRef = lines[collapsedNumberOfLines-1] as CTLineRef
                let modifiedLastLineText = textWithLinkReplacement(lastLineRef, lineText: text, linkName: link)
                
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
        if let location = location, linkRect = linkRect {
            let finger = CGRectMake(location.x-touchSize.width/2, location.y-touchSize.height/2, touchSize.width, touchSize.height);
            if collapsed && CGRectIntersectsRect(finger, linkRect) {
                linkHighlighted = highlighted
                attributedText = expandedText
                setNeedsDisplay()
                return true
            }
        }
        return false
    }
    
    private var collapsedAttributedHighlightedLink : NSAttributedString {
        get {
            let range = NSMakeRange(0, collapsedAttributedLink.length)
            let alphaComponent = CGFloat(0.5)
            var baseColor: UIColor? = collapsedAttributedLink.attribute(NSForegroundColorAttributeName, atIndex: 0, effectiveRange: nil) as? UIColor
            if let color = baseColor { baseColor = color.colorWithAlphaComponent(alphaComponent) }
            else { baseColor = textColor.colorWithAlphaComponent(alphaComponent) }
            var collapsedLinkHighlighted = NSMutableAttributedString(attributedString: collapsedAttributedLink)
            collapsedLinkHighlighted.removeAttribute(NSForegroundColorAttributeName, range: NSMakeRange(0, collapsedLinkHighlighted.length))
            collapsedLinkHighlighted.addAttribute(NSForegroundColorAttributeName, value: baseColor!, range: NSMakeRange(0, collapsedLinkHighlighted.length))
            return collapsedLinkHighlighted
        }
    }
    
    // MARK: Touch Handling
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        setLinkHighlighted(touches, event: event, highlighted: true)
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        setLinkHighlighted(touches, event: event, highlighted: false)
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        if setLinkHighlighted(touches, event: event, highlighted: false) {
            delegate?.willExpandLabel(self)
            collapsed = false
            delegate?.didExpandLabel(self)
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        setLinkHighlighted(touches, event: event, highlighted: false)
    }
}