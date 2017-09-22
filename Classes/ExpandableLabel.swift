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
    
    public enum TextReplacementType {
        case character
        case word
    }
    
    /// The delegate of ExpandableLabel
    weak open var delegate: ExpandableLabelDelegate?
    
    /// Set 'true' if the label should be collapsed or 'false' for expanded.
    @IBInspectable open var collapsed: Bool = true {
        didSet {
            super.attributedText = (collapsed) ? self.collapsedText : self.expandedText
            super.numberOfLines = (collapsed) ? self.collapsedNumberOfLines : 0
            if let animationView = animationView {
                UIView.animate(withDuration: 0.5) {
                    animationView.layoutIfNeeded()
                }
            }
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
    @objc open var collapsedAttributedLink: NSAttributedString! {
        didSet {
            self.collapsedAttributedLink = collapsedAttributedLink.copyWithAddedFontAttribute(font)
        }
    }
    
    /// Set the link name (and attributes) that is shown when expanded.
    /// The default value is "Less". Can be nil.
    @objc open var expandedAttributedLink: NSAttributedString?
    
    /// Set the ellipsis that appears just after the text and before the link.
    /// The default value is "...". Can be nil.
    @objc open var ellipsis: NSAttributedString? {
        didSet {
            self.ellipsis = ellipsis?.copyWithAddedFontAttribute(font)
        }
    }
    
    /// Set a view to animate changes of the label collapsed state with. If this value is nil, no animation occurs.
    /// Usually you assign the superview of this label or a UIScrollView in which this label sits.
    /// Also don't forget to set the contentMode of this label to top to smoothly reveal the hidden lines.
    /// The default value is 'nil'.
    @objc open var animationView: UIView?
    
    open var textReplacementType: TextReplacementType = .word
    
    
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
    fileprivate var collapsedLinkTextRange: NSRange?
    fileprivate var expandedLinkTextRange: NSRange?
    
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
        self.commonInit()
    }
    
    init() {
        super.init(frame: .zero)
    }
    
    fileprivate func commonInit() {
        self.isUserInteractionEnabled = true
        self.lineBreakMode = .byClipping
        self.numberOfLines = 3
        self.expandedAttributedLink = nil
        self.collapsedAttributedLink = NSAttributedString(string: "More", attributes: [.font: UIFont.boldSystemFont(ofSize: font.pointSize)])
        self.ellipsis = NSAttributedString(string: "...")
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
            if let attributedText = attributedText?.copyWithAddedFontAttribute(font), attributedText.length > 0 {
                self.collapsedText = getCollapsedText(for: attributedText, link: (linkHighlighted) ? collapsedAttributedLink.copyWithHighlightedColor() : self.collapsedAttributedLink)
                self.expandedText = getExpandedText(for: attributedText, link: (linkHighlighted) ? expandedAttributedLink?.copyWithHighlightedColor() : self.expandedAttributedLink)
                super.attributedText = (self.collapsed) ? self.collapsedText : self.expandedText
            } else {
                self.expandedText = nil
                self.collapsedText = nil
                super.attributedText = nil
            }
        }
        get {
            return super.attributedText
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    fileprivate func textReplaceWordWithLink(_ lineIndex: LineIndexTuple, text: NSAttributedString, linkName: NSAttributedString) -> NSAttributedString {
        let lineText = text.text(for: lineIndex.line)
        var lineTextWithLink = lineText
        (lineText.string as NSString).enumerateSubstrings(in: NSRange(location: 0, length: lineText.length), options: [.byWords, .reverse]) { (word, subRange, enclosingRange, stop) -> Void in
            let lineTextWithLastWordRemoved = lineText.attributedSubstring(from: NSRange(location: 0, length: subRange.location))
            let lineTextWithAddedLink = NSMutableAttributedString(attributedString: lineTextWithLastWordRemoved)
            if let ellipsis = self.ellipsis {
                lineTextWithAddedLink.append(ellipsis)
                lineTextWithAddedLink.append(NSAttributedString(string: " ", attributes: [.font: self.font]))
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
    
    fileprivate func textReplaceWithLink(_ lineIndex: LineIndexTuple, text: NSAttributedString, linkName: NSAttributedString) -> NSAttributedString {
        let lineText = text.text(for: lineIndex.line)
        let linkText = NSMutableAttributedString()
        if let ellipsis = self.ellipsis {
            linkText.append(ellipsis)
            linkText.append(NSAttributedString(string: " ", attributes: [.font: self.font]))
        }
        linkText.append(linkName)
        let truncatedString = lineText.attributedSubstring(from: NSMakeRange(0, lineText.length - linkText.length))
        let lineTextWithLink = NSMutableAttributedString(attributedString: truncatedString)
        lineTextWithLink.append(linkText)
        return lineTextWithLink
    }
    
    fileprivate func getExpandedText(for text: NSAttributedString?, link: NSAttributedString?) -> NSAttributedString? {
        guard let text = text else { return nil }
        let expandedText = NSMutableAttributedString()
        expandedText.append(text)
        if let link = link, textWillBeTruncated(expandedText) {
            let spaceOrNewLine = expandedLinkPosition == nil ? "  " : "\n"
            expandedText.append(NSMutableAttributedString(string: "\(spaceOrNewLine)\(link.string)", attributes: link.attributes(at: 0, effectiveRange: nil)))
            expandedLinkTextRange = NSMakeRange(expandedText.length - link.length, link.length)
        }
        
        return expandedText
    }
    
    fileprivate func getCollapsedText(for text: NSAttributedString?, link: NSAttributedString) -> NSAttributedString? {
        guard let text = text else { return nil }
        let lines = text.lines(for: frame.size.width)
        if collapsedNumberOfLines > 0 && collapsedNumberOfLines < lines.count {
            let lastLineRef = lines[collapsedNumberOfLines-1] as CTLine
            let lineIndex = findLineWithWords(lastLine: lastLineRef, text: text, lines: lines)
            let modifiedLastLineText = (self.textReplacementType == .word) ?
                textReplaceWordWithLink(lineIndex, text: text, linkName: link) :
                textReplaceWithLink(lineIndex, text: text, linkName: link)
            let collapsedLines = NSMutableAttributedString()
            for index in 0..<lineIndex.index {
                collapsedLines.append(text.text(for:lines[index]))
            }
            collapsedLines.append(modifiedLastLineText)
            collapsedLinkTextRange = NSMakeRange(collapsedLines.length - link.length, link.length)
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
    
    open override func sizeToFit() {
        super.sizeToFit()
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
        guard let touch = touches.first else {
            return
        }
        
        if !collapsed {
            guard let range = self.expandedLinkTextRange else {
                return
            }
            
            if shouldCollapse && ExpandableLabel.isTouchInLabelRange(touch: touch, label: self, inRange: range) {
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
    
    @objc static public func isTouchInLabelRange(
        touch: UITouch,
        label: UILabel,
        inRange targetRange: NSRange) -> Bool {
        
        guard let attributedText = label.attributedText else {
            return false
        }
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: attributedText)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let locationOfTouchInLabel = touch.location(in: label)
        
        if !textBoundingBox.contains(locationOfTouchInLabel) {
            return false
        }
        
        let locationOfTouchInTextContainer = CGPoint(
            x:locationOfTouchInLabel.x,
            y:locationOfTouchInLabel.y);
        let indexOfCharacter = layoutManager.characterIndex(
            for: locationOfTouchInTextContainer,
            in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        let characterBoundingRect = layoutManager.boundingRect(forGlyphRange: NSMakeRange(indexOfCharacter, 1), in: textContainer)
        if !characterBoundingRect.contains(locationOfTouchInTextContainer) {
            return false
        }
        
        return NSLocationInRange(Int(indexOfCharacter), targetRange)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        setLinkHighlighted(touches, event: event, highlighted: false)
    }
    
    open func setLessLinkWith(lessLink: String, attributes: [NSAttributedStringKey: AnyObject], position: NSTextAlignment?) {
        var alignedattributes = attributes
        if let pos = position {
            expandedLinkPosition = pos
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.alignment = pos
            alignedattributes[.paragraphStyle] = titleParagraphStyle
            
        }
        expandedAttributedLink = NSMutableAttributedString(string: lessLink,
                                                           attributes: alignedattributes)
    }
    
    fileprivate func textClicked(touches: Set<UITouch>?, event: UIEvent?) -> Bool {
        let touch = event?.allTouches?.first
        let location = touch?.location(in: self)
        let textRect = self.attributedText?.boundingRect(for: self.frame.width)
        if let location = location, let textRect = textRect {
            let finger = CGRect(x: location.x-touchSize.width/2, y: location.y-touchSize.height/2, width: touchSize.width, height: touchSize.height)
            if finger.intersects(textRect) {
                return true
            }
        }
        return false
    }
    
    @discardableResult fileprivate func setLinkHighlighted(_ touches: Set<UITouch>?, event: UIEvent?, highlighted: Bool) -> Bool {
        guard let touch = touches?.first else {
            return false
        }
        
        guard let range = self.collapsedLinkTextRange else {
            return false
        }
        
        if collapsed && ExpandableLabel.isTouchInLabelRange(touch: touch, label: self, inRange: range) {
            linkHighlighted = highlighted
            setNeedsDisplay()
            return true
        }
        return false
    }
}

// MARK: Convenience Methods

private extension NSAttributedString {
    func hasFontAttribute() -> Bool {
        guard !self.string.isEmpty else { return false }
        let font = self.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        return font != nil
    }
    
    func copyWithAddedFontAttribute(_ font: UIFont) -> NSAttributedString {
        if !hasFontAttribute() {
            let copy = NSMutableAttributedString(attributedString: self)
            copy.addAttribute(.font, value: font, range: NSRange(location: 0, length: copy.length))
            return copy
        }
        return self.copy() as! NSAttributedString
    }
    
    func copyWithHighlightedColor() -> NSAttributedString {
        let alphaComponent = CGFloat(0.5)
        let baseColor: UIColor = (self.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor)?.withAlphaComponent(alphaComponent) ?? UIColor.black.withAlphaComponent(alphaComponent)
        let highlightedCopy = NSMutableAttributedString(attributedString: self)
        let range = NSRange(location: 0, length: highlightedCopy.length)
        highlightedCopy.removeAttribute(.foregroundColor, range: range)
        highlightedCopy.addAttribute(.foregroundColor, value: baseColor, range: range)
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
