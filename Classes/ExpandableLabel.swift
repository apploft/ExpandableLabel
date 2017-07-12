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

typealias LineIndexTuple = (line: CTLine, index: Int)

import UIKit

/**
 * The delegate of ExpandableLabel.
 */
public protocol ExpandableLabelDelegate: NSObjectProtocol {
    func willExpandLabel(_ label: ExpandableLabel)
    func didExpandLabel(_ label: ExpandableLabel)
    
    func willCollapseLabel(_ label: ExpandableLabel)
    func didCollapseLabel(_ label: ExpandableLabel)
}

/**
 * ExpandableLabel
 */
open class ExpandableLabel: UILabel {
    
    /// The delegate of ExpandableLabel
    weak open var delegate: ExpandableLabelDelegate?
    
    /// Set 'true' if the label should be collapsed or 'false' for expanded.
    @IBInspectable open var collapsed: Bool = true {
        didSet {
            super.attributedText = (collapsed) ? self.collapsedText : self.expandedText
            super.numberOfLines = (collapsed) ? self.collapsedNumberOfLines : 0
        }
    }
    
    /// Set 'true' if the label can be expanded or 'false' if not.
    /// The default value is 'true'.
    @IBInspectable open var shouldExpand: Bool = true
    
    /// Set 'true' if the label can be collapsed or 'false' if not.
    /// The default value is 'false'.
    @IBInspectable open var shouldCollapse: Bool = false
    
    /// Set the link name (and attributes) that is shown when collapsed.
    /// The default value is "More". Cannot be nil.
    open var collapsedAttributedLink: NSAttributedString! {
        didSet {
            self.collapsedAttributedLink = collapsedAttributedLink.copyWithAddedFontAttribute(font)
        }
    }
    
    /// Set the link name (and attributes) that is shown when expanded.
    /// The default value is "Less". Can be nil.
    open var expandedAttributedLink: NSAttributedString?
    
    
    
    /// Set the ellipsis that appears just after the text and before the link.
    /// The default value is "...". Can be nil.
    open var ellipsis: NSAttributedString? {
        didSet {
            self.ellipsis = ellipsis?.copyWithAddedFontAttribute(font)
        }
    }
    
    
    //
    // MARK: Private
    //
    
    fileprivate var expandedText: NSAttributedString?
    fileprivate var collapsedText: NSAttributedString?
    fileprivate var linkHighlighted: Bool = false
    fileprivate let touchSize = CGSize(width: 44, height: 44)
    fileprivate var linkRect: CGRect?
    fileprivate var collapsedNumberOfLines: NSInteger = 0
    fileprivate var expandedLinkPosition: NSTextAlignment?
    
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
        super.init(frame: .zero)
    }
    
    fileprivate func commonInit() {
        isUserInteractionEnabled = true
        lineBreakMode = .byClipping
        numberOfLines = 3
        expandedAttributedLink = nil
        collapsedAttributedLink = NSAttributedString(string: "More", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: font.pointSize)])
        ellipsis = NSAttributedString(string: "...")
    }
    
    open override var text: String? {
        set(text) {
            if let text = text {
                expandedText = getExpandedText(for: text, link: expandedAttributedLink)?.copyWithAddedFontAttribute(font)
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
                self.collapsedText = getCollapsedText(for: attributedText, link: (linkHighlighted) ? collapsedAttributedLink.copyWithHighlightedColor() : collapsedAttributedLink)
                super.attributedText = (self.collapsed) ? self.collapsedText : self.expandedText
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
    
    fileprivate func textWithLinkReplacement(_ lineIndex: LineIndexTuple, text: NSAttributedString, linkName: NSAttributedString) -> NSAttributedString {
        let lineText = text.text(for: lineIndex.line)
        var lineTextWithLink = lineText
        (lineText.string as NSString).enumerateSubstrings(in: NSRange(location: 0, length: lineText.length), options: [.byWords, .reverse]) { (word, subRange, enclosingRange, stop) -> Void in
            let lineTextWithLastWordRemoved = lineText.attributedSubstring(from: NSRange(location: 0, length: subRange.location))
            let lineTextWithAddedLink = NSMutableAttributedString(attributedString: lineTextWithLastWordRemoved)
            if let ellipsis = self.ellipsis {
                lineTextWithAddedLink.append(ellipsis)
                lineTextWithAddedLink.append(NSAttributedString(string: " ", attributes: [NSFontAttributeName: self.font]))
            }
            lineTextWithAddedLink.append(linkName)
            let fits = self.textFitsWidth(lineTextWithAddedLink)
            if fits {
                lineTextWithLink = lineTextWithAddedLink
                let lineTextWithLastWordRemovedRect = lineTextWithLastWordRemoved.boundingRect(for: self.frame.size.width)
                let wordRect = linkName.boundingRect(for: self.frame.size.width)
                let width = lineTextWithLastWordRemoved.string == "" ? self.frame.width : wordRect.size.width
                self.linkRect = CGRect(x: lineTextWithLastWordRemovedRect.size.width, y: self.font.lineHeight * CGFloat(lineIndex.index), width: width, height: wordRect.size.height)
                stop.pointee = true
            }
        }
        return lineTextWithLink
    }
    
    fileprivate func getExpandedText(for text: String?, link: NSAttributedString?) -> NSAttributedString? {
        guard let text = text else { return nil }
        let expandedText = NSMutableAttributedString()
        expandedText.append(NSAttributedString(string: "\(text)", attributes: [ NSFontAttributeName: font]))
        if let link = link, textWillBeTruncated(expandedText) {
            let spaceOrNewLine = expandedLinkPosition == nil ? "  " : "\n"
            expandedText.append(NSMutableAttributedString(string: "\(spaceOrNewLine)\(link.string)", attributes: link.attributes(at: 0, effectiveRange: nil)))
        }
        
        return expandedText
    }
    
    fileprivate func getCollapsedText(for text: NSAttributedString?, link: NSAttributedString) -> NSAttributedString? {
        guard let text = text else { return nil }
        let lines = text.lines(for: frame.size.width)
        if collapsedNumberOfLines > 0 && collapsedNumberOfLines < lines.count {
            let lastLineRef = lines[collapsedNumberOfLines-1] as CTLine
            let lineIndex = findLineWithWords(lastLine: lastLineRef, text: text, lines: lines)
            let modifiedLastLineText = textWithLinkReplacement(lineIndex, text: text, linkName: link)
            let collapsedLines = NSMutableAttributedString()
            let differenceFromStart = (collapsedNumberOfLines-1) - lineIndex.index
            let emptyLineIndent = (2 + differenceFromStart)
            if collapsedNumberOfLines-emptyLineIndent > 0 {
                for index in 0...collapsedNumberOfLines-emptyLineIndent {
                    collapsedLines.append(text.text(for: lines[index]))
                }
            } else {
                collapsedLines.append(text.text(for: lines[0]))
            }
            collapsedLines.append(modifiedLastLineText)
            return collapsedLines
        }
        return text
    }
    
    
    fileprivate func findLineWithWords(lastLine: CTLine, text: NSAttributedString, lines: [CTLine]) -> LineIndexTuple {
        var lastLineRef = lastLine
        var lastLineIndex = collapsedNumberOfLines - 1
        var lineWords = spiltIntoWords(str: text.text(for: lastLineRef).string as NSString)
        while lineWords.count < 2 && lastLineIndex > 0 {
            lastLineIndex -=  1
            lastLineRef = lines[lastLineIndex] as CTLine
            lineWords = spiltIntoWords(str: text.text(for: lastLineRef).string as NSString)
        }
        return (lastLineRef, lastLineIndex)
    }
    
    fileprivate func spiltIntoWords(str: NSString) -> [String] {
        var strings: [String] = []
        str.enumerateSubstrings(in: NSRange(location: 0, length: str.length), options: [.byWords, .reverse]) { (word, subRange, enclosingRange, stop) -> Void in
            if let unwrappedWord = word {
                strings.append(unwrappedWord)
            }
            if strings.count > 1 { stop.pointee = true }
        }
        return strings
    }
    
    fileprivate func textFitsWidth(_ text: NSAttributedString) -> Bool {
        return (text.boundingRect(for: frame.size.width).size.height <= font.lineHeight) as Bool
    }
    
    fileprivate func textWillBeTruncated(_ text: NSAttributedString) -> Bool {
        let lines = text.lines(for: frame.size.width)
        return collapsedNumberOfLines > 0 && collapsedNumberOfLines < lines.count
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
            if shouldCollapse {
                delegate?.willCollapseLabel(self)
                collapsed = true
                delegate?.didCollapseLabel(self)
                linkHighlighted = isHighlighted
                setNeedsDisplay()
            }
        } else {
            if shouldExpand && setLinkHighlighted(touches, event: event, highlighted: false) {
                delegate?.willExpandLabel(self)
                collapsed = false
                delegate?.didExpandLabel(self)
            }
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        setLinkHighlighted(touches, event: event, highlighted: false)
    }
    
    open func setLessLinkWith(lessLink: String, attributes: [String: AnyObject], position: NSTextAlignment?) {
        var alignedattributes = attributes
        if let pos = position {
            expandedLinkPosition = pos
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.alignment = pos
            alignedattributes[NSParagraphStyleAttributeName] = titleParagraphStyle
            
        }
        expandedAttributedLink = NSMutableAttributedString(string: lessLink,
                                                           attributes: alignedattributes)
    }
    
    @discardableResult fileprivate func setLinkHighlighted(_ touches: Set<UITouch>?, event: UIEvent?, highlighted: Bool) -> Bool {
        let touch = event?.allTouches?.first
        let location = touch?.location(in: self)
        if let location = location, let linkRect = linkRect {
            let finger = CGRect(x: location.x-touchSize.width/2, y: location.y-touchSize.height/2, width: touchSize.width, height: touchSize.height)
            if collapsed && finger.intersects(linkRect) {
                linkHighlighted = highlighted
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
        guard !self.string.isEmpty else { return false }
        let font = self.attribute(NSFontAttributeName, at: 0, effectiveRange: nil) as? UIFont
        return font != nil
    }
    
    func copyWithAddedFontAttribute(_ font: UIFont) -> NSAttributedString {
        if !hasFontAttribute() {
            let copy = NSMutableAttributedString(attributedString: self)
            copy.addAttribute(NSFontAttributeName, value: font, range: NSRange(location: 0, length: copy.length))
            return copy
        }
        return self.copy() as! NSAttributedString
    }
    
    func copyWithHighlightedColor() -> NSAttributedString {
        let alphaComponent = CGFloat(0.5)
        let baseColor: UIColor = (self.attribute(NSForegroundColorAttributeName, at: 0, effectiveRange: nil) as? UIColor)?.withAlphaComponent(alphaComponent) ?? UIColor.black.withAlphaComponent(alphaComponent)
        let highlightedCopy = NSMutableAttributedString(attributedString: self)
        let range = NSRange(location: 0, length: highlightedCopy.length)
        highlightedCopy.removeAttribute(NSForegroundColorAttributeName, range: range)
        highlightedCopy.addAttribute(NSForegroundColorAttributeName, value: baseColor, range: range)
        return highlightedCopy
    }
    
    func lines(for width: CGFloat) -> [CTLine] {
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        let frameSetterRef: CTFramesetter = CTFramesetterCreateWithAttributedString(self as CFAttributedString)
        let frameRef: CTFrame = CTFramesetterCreateFrame(frameSetterRef, CFRange(location: 0, length: 0), path.cgPath, nil)
        
        let linesNS: NSArray  = CTFrameGetLines(frameRef)
        let linesAO: [AnyObject] = linesNS as [AnyObject]
        let lines: [CTLine] = linesAO as! [CTLine]
        
        return lines
    }
    
    func text(for lineRef: CTLine) -> NSAttributedString {
        let lineRangeRef: CFRange = CTLineGetStringRange(lineRef)
        let range: NSRange = NSRange(location: lineRangeRef.location, length: lineRangeRef.length)
        return self.attributedSubstring(from: range)
    }
    
    func boundingRect(for width: CGFloat) -> CGRect {
        return self.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                 options: .usesLineFragmentOrigin, context: nil)
    }
}
