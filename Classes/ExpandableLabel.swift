//
// ExpandableLabel.swift
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
    @IBInspectable var collapsedAttributedLink : NSAttributedString! {
        didSet {
            self.collapsedAttributedLink = collapsedAttributedLink.copyWithAddedFontAttribute(font)
        }
    }
    
    /// Set the ellipsis that appears just after the text and before the link.
    /// The default value is "...". Can be nil.
    var ellipsis : NSAttributedString?{
        didSet {
            self.ellipsis = ellipsis?.copyWithAddedFontAttribute(font)
        }
    }
    
    
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
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    init() {
        super.init(frame: CGRectZero)
    }
    
    private func commonInit() {
        userInteractionEnabled = true
        lineBreakMode = NSLineBreakMode.ByClipping
        numberOfLines = 3
        collapsedAttributedLink = NSAttributedString(string: "More", attributes: [NSFontAttributeName : UIFont.boldSystemFontOfSize(font.pointSize)])
        ellipsis = NSAttributedString(string: "...")
    }
    
    override var text: String? {
        set(text) {
            if let text = text {
                self.attributedText = NSAttributedString(string: text)
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
                self.expandedText = attributedText.copyWithAddedFontAttribute(font)
                self.collapsedText = getCollapsedTextForText(self.expandedText, link: (linkHighlighted) ? collapsedAttributedLink.copyWithHighlightedColor() : collapsedAttributedLink)
                super.attributedText = (self.collapsed) ? self.collapsedText : self.expandedText;
            } else {
                super.attributedText = nil
            }
        }
        get {
            return super.attributedText
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        attributedText = expandedText
    }
    
    private func textWithLinkReplacement(line : CTLineRef, text : NSAttributedString, linkName : NSAttributedString) -> NSAttributedString {
        let lineText = text.textForLine(line)
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
                let lineTextWithLastWordRemovedRect = lineTextWithLastWordRemoved.rect(self.frame)
                let wordRect = linkName.rect(self.frame)
                self.linkRect = CGRectMake(lineTextWithLastWordRemovedRect.size.width, self.font.lineHeight * CGFloat(self.collapsedNumberOfLines-1), wordRect.size.width, wordRect.size.height)
                stop.memory = true
            }
        }
        return lineTextWithLink
    }

    
    private func getCollapsedTextForText(text : NSAttributedString?, link: NSAttributedString) -> NSAttributedString? {
        if let text = text {
            let lines = text.getLinesArrayOfAttributedText(frame)
            if (collapsedNumberOfLines > 0 && collapsedNumberOfLines < lines.count) {
                let lastLineRef = lines[collapsedNumberOfLines-1] as CTLineRef
                let modifiedLastLineText = textWithLinkReplacement(lastLineRef, text: text, linkName: link)
                
                var collapsedLines = NSMutableAttributedString()
                if (collapsedNumberOfLines >= 2) {
                    for index in 0...collapsedNumberOfLines-2 {
                        collapsedLines.appendAttributedString(text.textForLine(lines[index]))
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
        return (text.rect(frame).size.height <= font.lineHeight) as Bool
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
}

// MARK: Convenience Methods

private extension NSAttributedString {
    func hasFontAttribute() -> Bool {
        let font = self.attribute(NSFontAttributeName, atIndex: 0, effectiveRange: nil) as? UIFont
        return font != nil
    }
    
    func copyWithAddedFontAttribute(font : UIFont) -> NSAttributedString {
        if (hasFontAttribute() == false) {
            var copy = NSMutableAttributedString(attributedString: self)
            copy.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, copy.length))
            return copy
        }
        return self.copy() as! NSAttributedString
    }
    
    func copyWithHighlightedColor() -> NSAttributedString {
        let range = NSMakeRange(0, self.length)
        let alphaComponent = CGFloat(0.5)
        var baseColor: UIColor? = self.attribute(NSForegroundColorAttributeName, atIndex: 0, effectiveRange: nil) as? UIColor
        if let color = baseColor { baseColor = color.colorWithAlphaComponent(alphaComponent) }
        else { baseColor = UIColor.blackColor().colorWithAlphaComponent(alphaComponent) }
        var highlightedCopy = NSMutableAttributedString(attributedString: self)
        highlightedCopy.removeAttribute(NSForegroundColorAttributeName, range: NSMakeRange(0, highlightedCopy.length))
        highlightedCopy.addAttribute(NSForegroundColorAttributeName, value: baseColor!, range: NSMakeRange(0, highlightedCopy.length))
        return highlightedCopy
    }
    
    func getLinesArrayOfAttributedText(frame : CGRect) -> Array<CTLineRef> {
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: frame.size.width, height: CGFloat(MAXFLOAT)))
        let frameSetterRef : CTFramesetterRef = CTFramesetterCreateWithAttributedString(self as CFAttributedStringRef)
        let frameRef : CTFrameRef = CTFramesetterCreateFrame(frameSetterRef, CFRangeMake(0, 0), path.CGPath, nil)
        return CTFrameGetLines(frameRef) as! Array<CTLineRef>
    }
    
    func textForLine(lineRef : CTLineRef) -> NSAttributedString {
        let lineRangeRef : CFRange = CTLineGetStringRange(lineRef)
        let range : NSRange = NSMakeRange(lineRangeRef.location, lineRangeRef.length)
        return self.attributedSubstringFromRange(range)
    }
    
    func rect(frame : CGRect) -> CGRect {
        return self.boundingRectWithSize(CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT)),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
    }
}
