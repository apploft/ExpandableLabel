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
@objc public protocol ExpandableLabelDelegate: NSObjectProtocol {
    @objc func willExpandLabel(_ label: ExpandableLabel)
    @objc func didExpandLabel(_ label: ExpandableLabel)
    @objc func willCollapseLabel(_ label: ExpandableLabel)
    @objc func didCollapseLabel(_ label: ExpandableLabel)
}

/**
 * ExpandableLabel
 */
@objc open class ExpandableLabel: UILabel {
    public enum TextReplacementType {
        case character
        case word
    }

    /// The delegate of ExpandableLabel
    @objc weak open var delegate: ExpandableLabelDelegate?

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

    private var collapsedText: NSAttributedString?
    private var linkHighlighted: Bool = false
    private let touchSize = CGSize(width: 44, height: 44)
    private var linkRect: CGRect?
    private var collapsedNumberOfLines: NSInteger = 0
    private var expandedLinkPosition: NSTextAlignment?
    private var collapsedLinkTextRange: NSRange?
    private var expandedLinkTextRange: NSRange?

    open override var numberOfLines: NSInteger {
        didSet {
            collapsedNumberOfLines = numberOfLines
        }
    }

    @objc public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    @objc public init() {
        super.init(frame: .zero)
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

    open private(set) var expandedText: NSAttributedString?
    open override var attributedText: NSAttributedString? {
        set(attributedText) {
            if let attributedText = attributedText?.copyWithAddedFontAttribute(font).copyWithParagraphAttribute(font),
                attributedText.length > 0 {
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

    open func setLessLinkWith(lessLink: String, attributes: [NSAttributedString.Key: AnyObject], position: NSTextAlignment?) {
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
}

// MARK: - Touch Handling

extension ExpandableLabel {

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

            if shouldCollapse && check(touch: touch, isInRange: range) {
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
}

// MARK: Privates

extension ExpandableLabel {
    private func commonInit() {
        isUserInteractionEnabled = true
        lineBreakMode = .byClipping
        collapsedNumberOfLines = numberOfLines
        expandedAttributedLink = nil
        collapsedAttributedLink = NSAttributedString(string: "More", attributes: [.font: UIFont.boldSystemFont(ofSize: font.pointSize)])
        ellipsis = NSAttributedString(string: "...")
    }

    private func textReplaceWordWithLink(_ lineIndex: LineIndexTuple, text: NSAttributedString, linkName: NSAttributedString) -> NSAttributedString {
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

    private func textReplaceWithLink(_ lineIndex: LineIndexTuple, text: NSAttributedString, linkName: NSAttributedString) -> NSAttributedString {
        let lineText = text.text(for: lineIndex.line)
        let lineTextTrimmedNewLines = NSMutableAttributedString()
        lineTextTrimmedNewLines.append(lineText)
        let nsString = lineTextTrimmedNewLines.string as NSString
        let range = nsString.rangeOfCharacter(from: CharacterSet.newlines)
        if range.length > 0 {
            lineTextTrimmedNewLines.replaceCharacters(in: range, with: "")
        }
        let linkText = NSMutableAttributedString()
        if let ellipsis = self.ellipsis {
            linkText.append(ellipsis)
            linkText.append(NSAttributedString(string: " ", attributes: [.font: self.font]))
        }
        linkText.append(linkName)

        let lengthDifference = lineTextTrimmedNewLines.string.composedCount - linkText.string.composedCount
        let truncatedString = lineTextTrimmedNewLines.attributedSubstring(
            from: NSMakeRange(0, lengthDifference >= 0 ? lengthDifference : lineTextTrimmedNewLines.string.composedCount))
        let lineTextWithLink = NSMutableAttributedString(attributedString: truncatedString)
        lineTextWithLink.append(linkText)
        return lineTextWithLink
    }

    private func getExpandedText(for text: NSAttributedString?, link: NSAttributedString?) -> NSAttributedString? {
        guard let text = text else { return nil }
        let expandedText = NSMutableAttributedString()
        expandedText.append(text)
        if let link = link, textWillBeTruncated(expandedText) {
            let spaceOrNewLine = expandedLinkPosition == nil ? "  " : "\n"
            expandedText.append(NSAttributedString(string: "\(spaceOrNewLine)"))
            expandedText.append(NSMutableAttributedString(string: "\(link.string)", attributes: link.attributes(at: 0, effectiveRange: nil)).copyWithAddedFontAttribute(font))
            expandedLinkTextRange = NSMakeRange(expandedText.length - link.length, link.length)
        }

        return expandedText
    }

    private func getCollapsedText(for text: NSAttributedString?, link: NSAttributedString) -> NSAttributedString? {
        guard let text = text else { return nil }
        let lines = text.lines(for: frame.size.width)
        if collapsedNumberOfLines > 0 && collapsedNumberOfLines < lines.count {
            let lastLineRef = lines[collapsedNumberOfLines-1] as CTLine
            var lineIndex: LineIndexTuple?
            var modifiedLastLineText: NSAttributedString?

            if self.textReplacementType == .word {
                lineIndex = findLineWithWords(lastLine: lastLineRef, text: text, lines: lines)
                if let lineIndex = lineIndex {
                    modifiedLastLineText = textReplaceWordWithLink(lineIndex, text: text, linkName: link)
                }
            } else {
                lineIndex = (lastLineRef, collapsedNumberOfLines - 1)
                if let lineIndex = lineIndex {
                    modifiedLastLineText = textReplaceWithLink(lineIndex, text: text, linkName: link)
                }
            }

            if let lineIndex = lineIndex, let modifiedLastLineText = modifiedLastLineText {
                let collapsedLines = NSMutableAttributedString()
                for index in 0..<lineIndex.index {
                    collapsedLines.append(text.text(for:lines[index]))
                }
                collapsedLines.append(modifiedLastLineText)

                collapsedLinkTextRange = NSRange(location: collapsedLines.length - link.length, length: link.length)
                return collapsedLines
            } else {
                return nil
            }
        }
        return text
    }

    private func findLineWithWords(lastLine: CTLine, text: NSAttributedString, lines: [CTLine]) -> LineIndexTuple {
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

    private func spiltIntoWords(str: NSString) -> [String] {
        var strings: [String] = []
        str.enumerateSubstrings(in: NSRange(location: 0, length: str.length), options: [.byWords, .reverse]) { (word, subRange, enclosingRange, stop) -> Void in
            if let unwrappedWord = word {
                strings.append(unwrappedWord)
            }
            if strings.count > 1 { stop.pointee = true }
        }
        return strings
    }

    private func textFitsWidth(_ text: NSAttributedString) -> Bool {
        return (text.boundingRect(for: frame.size.width).size.height <= font.lineHeight) as Bool
    }

    private func textWillBeTruncated(_ text: NSAttributedString) -> Bool {
        let lines = text.lines(for: frame.size.width)
        return collapsedNumberOfLines > 0 && collapsedNumberOfLines < lines.count
    }

    private func textClicked(touches: Set<UITouch>?, event: UIEvent?) -> Bool {
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

    @discardableResult private func setLinkHighlighted(_ touches: Set<UITouch>?, event: UIEvent?, highlighted: Bool) -> Bool {
        guard let touch = touches?.first else {
            return false
        }

        guard let range = self.collapsedLinkTextRange else {
            return false
        }

        if collapsed && check(touch: touch, isInRange: range) {
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

    func copyWithParagraphAttribute(_ font: UIFont) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.05
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 0.0
        paragraphStyle.minimumLineHeight = font.lineHeight
        paragraphStyle.maximumLineHeight = font.lineHeight

        let copy = NSMutableAttributedString(attributedString: self)
        let range = NSRange(location: 0, length: copy.length)
        copy.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        copy.addAttribute(.baselineOffset, value: font.pointSize * 0.08, range: range)
        return copy
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
        let baseColor: UIColor = (self.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor)?.withAlphaComponent(alphaComponent) ??
            UIColor.black.withAlphaComponent(alphaComponent)
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

extension String {
    var composedCount : Int {
        var count = 0
        enumerateSubstrings(in: startIndex..<endIndex, options: .byComposedCharacterSequences) { _,_,_,_  in count += 1 }
        return count
    }
}

extension UILabel {
    open func check(touch: UITouch, isInRange targetRange: NSRange) -> Bool {
        let touchPoint = touch.location(in: self)
        let index = characterIndex(at: touchPoint)
        return NSLocationInRange(index, targetRange)
    }

    private func characterIndex(at touchPoint: CGPoint) -> Int {
        guard let attributedString = attributedText else { return NSNotFound }
        if !bounds.contains(touchPoint) {
            return NSNotFound
        }

        let textRect = self.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        if !textRect.contains(touchPoint) {
            return NSNotFound
        }

        var point = touchPoint
        // Offset tap coordinates by textRect origin to make them relative to the origin of frame
        point = CGPoint(x: point.x - textRect.origin.x, y: point.y - textRect.origin.y)
        // Convert tap coordinates (start at top left) to CT coordinates (start at bottom left)
        point = CGPoint(x: point.x, y: textRect.size.height - point.y)

        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, attributedString.length), nil, CGSize(width: textRect.width, height: CGFloat.greatestFiniteMagnitude), nil)

        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: suggestedSize.width, height: CGFloat(ceilf(Float(suggestedSize.height)))))

        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedString.length), path, nil)
        let lines = CTFrameGetLines(frame)
        let linesCount = numberOfLines > 0 ? min(numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines)
        if linesCount == 0 {
            return NSNotFound
        }

        var lineOrigins = [CGPoint](repeating: .zero, count: linesCount)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, linesCount), &lineOrigins)

        for (idx, lineOrigin) in lineOrigins.enumerated() {
            var lineOrigin = lineOrigin
            let lineIndex = CFIndex(idx)
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, lineIndex), to: CTLine.self)

            // Get bounding information of line
            var ascent: CGFloat = 0.0
            var descent: CGFloat = 0.0
            var leading: CGFloat = 0.0
            let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
            let yMin = CGFloat(floor(lineOrigin.y - descent))
            let yMax = CGFloat(ceil(lineOrigin.y + ascent))

            // Apply penOffset using flushFactor for horizontal alignment to set lineOrigin since this is the horizontal offset from drawFramesetter
            let flushFactor = flushFactorForTextAlignment(textAlignment: textAlignment)
            let penOffset = CGFloat(CTLineGetPenOffsetForFlush(line, flushFactor, Double(textRect.size.width)))
            lineOrigin.x = penOffset

            // Check if we've already passed the line
            if point.y > yMax {
                return NSNotFound
            }
            // Check if the point is within this line vertically
            if point.y >= yMin {
                // Check if the point is within this line horizontally
                if point.x >= lineOrigin.x && point.x <= lineOrigin.x + width {
                    // Convert CT coordinates to line-relative coordinates
                    let relativePoint = CGPoint(x: point.x - lineOrigin.x, y: point.y - lineOrigin.y)
                    return Int(CTLineGetStringIndexForPosition(line, relativePoint))
                }
            }
        }

        return NSNotFound
    }

    private func flushFactorForTextAlignment(textAlignment: NSTextAlignment) -> CGFloat {
        switch textAlignment {
        case .center:
            return 0.5
        case .right:
            return 1.0
        case .left, .natural, .justified:
            return 0.0
        }
    }
}


