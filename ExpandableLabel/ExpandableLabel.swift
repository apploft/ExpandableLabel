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
            super.text = (collapsed) ? self.collapsedText : self.expandedText
            super.numberOfLines = (collapsed) ? collapsedNumberOfLines : 0
        }
    }
    var collapsedLinkName : String = "Mehr"
    
    override var text: String? {
        
        set(text) {
            self.expandedText = text
            self.collapsedText = getCollapsedTextForText(text)
            super.text = (self.collapsed) ? self.collapsedText : self.expandedText;
        }
        
        get {
            return super.text
        }
    }
    
    //
    // MARK: Private
    //
    
    private var expandedText : String?
    private var collapsedText : String?

    private func getLinesArrayOfText(text : String) -> NSArray {
        
        let fontRef : CTFontRef = CTFontCreateWithName(font.fontName as CFStringRef, font.pointSize, nil)
        let attStr = NSMutableAttributedString(string: text)
        attStr.addAttribute(kCTFontAttributeName as String, value: fontRef, range: NSMakeRange(0, attStr.length))
        
        let frameSetter : CTFramesetterRef = CTFramesetterCreateWithAttributedString(attStr as CFAttributedStringRef)
        var path = CGPathCreateMutable()
        CGPathAddRect(path, nil, CGRect(x: 0, y: 0, width: frame.size.width, height: CGFloat(MAXFLOAT)))
        
        let frameRef : CTFrameRef = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        let lines : NSArray = CTFrameGetLines(frameRef) as NSArray
        
        var linesArray : NSMutableArray = NSMutableArray()
        
        
        for line in lines {
            let lineRef : CTLineRef = line as! CTLineRef
            let lineRange : CFRange = CTLineGetStringRange(lineRef)
            let range : NSRange = NSMakeRange(lineRange.location, lineRange.length)
            
            let lineString : NSString = (text as NSString?)!.substringWithRange(range)
            
            CFAttributedStringSetAttribute(attStr as CFMutableAttributedStringRef, lineRange, kCTKernAttributeName, 0 as CFTypeRef)
            CFAttributedStringSetAttribute(attStr as CFMutableAttributedStringRef, lineRange, kCTKernAttributeName, 0.0 as CFTypeRef)
            
            linesArray.addObject(lineString)
        }
        
        return linesArray
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        text = expandedText
    }
    
    private func textFitsWidth(text : NSString) -> Bool {
        let rect : CGRect = text.boundingRectWithSize(CGSize(width: self.frame.size.width, height: CGFloat(MAXFLOAT)),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName : font], context: nil)
        return (rect.size.height <= font.lineHeight) as Bool
    }
    
    private func textWithLinkReplacement(text : NSString, linkName : NSString) -> NSString {
        var newText : NSString = text
        text.enumerateSubstringsInRange(NSMakeRange(0, text.length), options: .ByWords | .Reverse) { (word, subRange, enclosingRange, stop) -> () in
            newText = text.substringWithRange(NSMakeRange(0, subRange.location)).stringByAppendingFormat("%@", linkName)
            let fits = self.textFitsWidth(newText as String)
            if (fits == true) {
                stop.memory = true
            }
        }
        return newText
    }

    
    private func getCollapsedTextForText(text : String?) -> String? {
        if let text = text {
            let lines = getLinesArrayOfText(text)
            if (collapsedNumberOfLines <= lines.count) {
                var lastLine = lines[collapsedNumberOfLines-1] as! NSString
                var modifiedLastLine = textWithLinkReplacement(lastLine, linkName: collapsedLinkName)
                var collapsedLines = lines.subarrayWithRange(NSMakeRange(0, collapsedNumberOfLines-1))
                collapsedLines.append(modifiedLastLine)
                return (collapsedLines as NSArray).componentsJoinedByString(String())
            }
            return lines.componentsJoinedByString(String())
        } else {
            return nil;
        }
    }
}