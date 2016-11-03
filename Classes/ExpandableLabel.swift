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
public protocol ExpandableLabelDelegate : NSObjectProtocol {
    func willExpandLabel(_ label: ExpandableLabel)
    func didExpandLabel(_ label: ExpandableLabel)
    func shouldExpandLabel(_ label: ExpandableLabel) -> Bool
    
    func willCollapseLabel(_ label: ExpandableLabel)
    func didCollapseLabel(_ label: ExpandableLabel)
    func shouldCollapseLabel(_ label: ExpandableLabel) -> Bool
}

extension ExpandableLabelDelegate {
    public func shouldExpandLabel(_ label: ExpandableLabel) -> Bool {
        return Static.DefaultShouldExpandValue
    }
    public func shouldCollapseLabel(_ label: ExpandableLabel) -> Bool {
        return Static.DefaultShouldCollapseValue
    }
    public func willCollapseLabel(_ label: ExpandableLabel) {}
    public func didCollapseLabel(_ label: ExpandableLabel) {}
}

private struct Static {
    fileprivate static let DefaultShouldExpandValue : Bool = true
    fileprivate static let DefaultShouldCollapseValue : Bool = false
}

/**
 * ExpandableLabel
 */
open class ExpandableLabel : UILabel {
    
    /// The delegate of ExpandableLabel
    weak open var delegate: ExpandableLabelDelegate?
    
    /// Set 'true' if the label should be collapsed or 'false' for expanded.
    @IBInspectable open var collapsed : Bool = true {
        didSet {
            super.attributedText = (collapsed) ? self.collapsedText : self.expandedText
            super.numberOfLines = (collapsed) ? self.collapsedNumberOfLines : 0
        }
    }
    
    /// Set the link name (and attributes) that is shown when collapsed.
    /// The default value is "More". Cannot be nil.
    @IBInspectable open var collapsedAttributedLink : NSAttributedString! {
        didSet {
            self.collapsedAttributedLink = collapsedAttributedLink.copyWithAddedFontAttribute(font)
        }
    }
    
    /// Set the ellipsis that appears just after the text and before the link.
    /// The default value is "...". Can be nil.
    open var ellipsis : NSAttributedString?{
        didSet {
            self.ellipsis = ellipsis?.copyWithAddedFontAttribute(font)
        }
    }
    
    
    //
    // MARK: Private
    //
    
    fileprivate var expandedText : NSAttributedString?
    fileprivate var collapsedText : NSAttributedString?
    fileprivate var linkHighlighted : Bool = false
    fileprivate let touchSize = CGSize(width: 44, height: 44)
    fileprivate var linkRect : CGRect?
    fileprivate var collapsedNumberOfLines : NSInteger = 0
    
    open override var numberOfLines: NSInteger {
        didSet {
            collapsedNumberOfLines = numberOfLines
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    init() {
        super.init(frame: CGRect.zero)
    }
    
    fileprivate func commonInit() {
        isUserInteractionEnabled = true
        lineBreakMode = NSLineBreakMode.byClipping
        numberOfLines = 3
        collapsedAttributedLink = NSAttributedString(string: "More", attributes: [NSFontAttributeName : UIFont.boldSystemFont(ofSize: font.pointSize)])
        ellipsis = NSAttributedString(string: "...")
    }
    
    open override var text: String? {
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
    
    open override var attributedText: NSAttributedString? {
        set(attributedText) {
            if let attributedText = attributedText, attributedText.length > 0 {
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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        attributedText = expandedText
    }
    
    fileprivate func textWithLinkReplacement(_ line : CTLine, text : NSAttributedString, linkName : NSAttributedString) -> NSAttributedString {
        let lineText = text.textForLine(line)
        var lineTextWithLink = lineText
        (lineText.string as NSString).enumerateSubstrings(in: NSMakeRange(0, lineText.length), options: [.byWords, .reverse]) { (word, subRange, enclosingRange, stop) -> () in
            let lineTextWithLastWordRemoved = lineText.attributedSubstring(from: NSMakeRange(0, subRange.location))
            let lineTextWithAddedLink = NSMutableAttributedString(attributedString: lineTextWithLastWordRemoved)
            if let ellipsis = self.ellipsis {
                lineTextWithAddedLink.append(ellipsis)
                lineTextWithAddedLink.append(NSAttributedString(string: " ", attributes: [NSFontAttributeName : self.font]))
            }
            lineTextWithAddedLink.append(linkName)
            let fits = self.textFitsWidth(lineTextWithAddedLink)
            if (fits == true) {
                lineTextWithLink = lineTextWithAddedLink
                let lineTextWithLastWordRemovedRect = lineTextWithLastWordRemoved.boundingRectForWidth(self.frame.size.width)
                let wordRect = linkName.boundingRectForWidth(self.frame.size.width)
                self.linkRect = CGRect(x: lineTextWithLastWordRemovedRect.size.width, y: self.font.lineHeight * CGFloat(self.collapsedNumberOfLines-1), width: wordRect.size.width, height: wordRect.size.height)
                stop.pointee = true
            }
        }
        return lineTextWithLink
    }
    
    
    fileprivate func getCollapsedTextForText(_ text : NSAttributedString?, link: NSAttributedString) -> NSAttributedString? {
        if let text = text {
            let lines = text.linesForWidth(frame.size.width)
            if (collapsedNumberOfLines > 0 && collapsedNumberOfLines < lines.count) {
                let lastLineRef = lines[collapsedNumberOfLines-1] as CTLine
                let modifiedLastLineText = textWithLinkReplacement(lastLineRef, text: text, linkName: link)
                
                let collapsedLines = NSMutableAttributedString()
                if (collapsedNumberOfLines >= 2) {
                    for index in 0...collapsedNumberOfLines-2 {
                        collapsedLines.append(text.textForLine(lines[index]))
                    }
                }
                collapsedLines.append(modifiedLastLineText)
                return collapsedLines
            }
            return text
        } else {
            return nil;
        }
    }
    
    fileprivate func textFitsWidth(_ text : NSAttributedString) -> Bool {
        return (text.boundingRectForWidth(frame.size.width).size.height <= font.lineHeight) as Bool
    }
    
    // MARK: Touch Handling
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        setLinkHighlighted(touches, event: event, highlighted: true)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        setLinkHighlighted(touches, event: event, highlighted: false)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !collapsed {
            if shouldCollapse() {
                delegate?.willCollapseLabel(self)
                collapsed = true
                delegate?.didCollapseLabel(self)
                linkHighlighted = isHighlighted
                setNeedsDisplay()
            }
        }else{
            if shouldExpand() && setLinkHighlighted(touches, event: event, highlighted: false) {
                delegate?.willExpandLabel(self)
                collapsed = false
                delegate?.didExpandLabel(self)
            }
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        setLinkHighlighted(touches, event: event, highlighted: false)
    }
    
    @discardableResult fileprivate func setLinkHighlighted(_ touches: Set<UITouch>?, event: UIEvent?, highlighted : Bool) -> Bool {
        let touch = event?.allTouches?.first
        let location = touch?.location(in: self)
        if let location = location, let linkRect = linkRect {
            let finger = CGRect(x: location.x-touchSize.width/2, y: location.y-touchSize.height/2, width: touchSize.width, height: touchSize.height);
            if collapsed && finger.intersects(linkRect) {
                linkHighlighted = highlighted
                setNeedsDisplay()
                return true
            }
        }
        return false
    }
    
    fileprivate func shouldCollapse() -> Bool {
        return delegate?.shouldCollapseLabel(self) ?? Static.DefaultShouldCollapseValue
    }
    
    fileprivate func shouldExpand() -> Bool {
        return delegate?.shouldExpandLabel(self) ?? Static.DefaultShouldExpandValue
    }
}

// MARK: Convenience Methods

private extension NSAttributedString {
    func hasFontAttribute() -> Bool {
        let font = self.attribute(NSFontAttributeName, at: 0, effectiveRange: nil) as? UIFont
        return font != nil
    }
    
    func copyWithAddedFontAttribute(_ font : UIFont) -> NSAttributedString {
        if (hasFontAttribute() == false) {
            let copy = NSMutableAttributedString(attributedString: self)
            copy.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, copy.length))
            return copy
        }
        return self.copy() as! NSAttributedString
    }
    
    func copyWithHighlightedColor() -> NSAttributedString {
        let alphaComponent = CGFloat(0.5)
        var baseColor: UIColor? = self.attribute(NSForegroundColorAttributeName, at: 0, effectiveRange: nil) as? UIColor
        if let color = baseColor { baseColor = color.withAlphaComponent(alphaComponent) }
        else { baseColor = UIColor.black.withAlphaComponent(alphaComponent) }
        let highlightedCopy = NSMutableAttributedString(attributedString: self)
        highlightedCopy.removeAttribute(NSForegroundColorAttributeName, range: NSMakeRange(0, highlightedCopy.length))
        highlightedCopy.addAttribute(NSForegroundColorAttributeName, value: baseColor!, range: NSMakeRange(0, highlightedCopy.length))
        return highlightedCopy
    }
    
    func linesForWidth(_ width : CGFloat) -> Array<CTLine> {
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: width, height: CGFloat(MAXFLOAT)))
        let frameSetterRef : CTFramesetter = CTFramesetterCreateWithAttributedString(self as CFAttributedString)
        let frameRef : CTFrame = CTFramesetterCreateFrame(frameSetterRef, CFRangeMake(0, 0), path.cgPath, nil)
        
        let linesNS: NSArray  = CTFrameGetLines(frameRef)
        let linesAO: [AnyObject] = linesNS as [AnyObject]
        let lines: [CTLine] = linesAO as! [CTLine]
        
        return lines
    }
    
    func textForLine(_ lineRef : CTLine) -> NSAttributedString {
        let lineRangeRef : CFRange = CTLineGetStringRange(lineRef)
        let range : NSRange = NSMakeRange(lineRangeRef.location, lineRangeRef.length)
        return self.attributedSubstring(from: range)
    }
    
    func boundingRectForWidth(_ width : CGFloat) -> CGRect {
        return self.boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)),
                                         options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
    }
}
