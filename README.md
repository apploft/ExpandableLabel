# ExpandableLabel
ExpandableLabel is a simple UILabel subclass that shows a tappable link if the content doesn't fit the specified number of lines. If touched, the label will expand to show the entire content.

<img src="https://raw.githubusercontent.com/apploft/ExpandableLabel/master/Resources/ExpandableLabel.gif">

## Maintenance
This project is passively maintained. Pull Requests are welcome, will be reviewed, merged and released as new CocoaPod version as long as they don't break things.
Nevertheless we don't have the resources to actively continue development, answer issues or give support for integration.

# Installation

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

Add this to your Podfile:

```ruby
pod "ExpandableLabel"
```

### [Carthage](https://github.com/Carthage/Carthage)

Add this to your Cartfile:

```ruby
github "apploft/ExpandableLabel"
```

Run `carthage` to build the framework and drag the built `ExpandableLabel.framework` into your Xcode project.

# Usage
Using ExpandableLabel is very simple. In your storyboard, set the custom class of your UILabel to ExpandableLabel and set the desired number of lines (for the collapsed state):

_**Note:** In Carthage, set Module to `ExpandableLabel`._

```swift
expandableLabel.numberOfLines = 3
```

Apart from that, one can modify the following settings:

##### delegate
Set a delegate to get notified in case the link has been touched.

##### collapsed
Set _true_ if the label should be collapsed or _false_ for expanded.

```swift
expandableLabel.collapsed = true
```

##### collapsedAttributedLink
Set the link name (and attributes) that is shown when collapsed.

```swift
expandableLabel.collapsedAttributedLink = NSAttributedString(string: "Read More")
```

##### expandedAttributedLink
Set the link name (and attributes) that is shown when expanded.
It is optional and can be nil.

```swift
expandableLabel.expandedAttributedLink = NSAttributedString(string: "Read Less")
```

##### setLessLinkWith(lessLink: String, attributes: [String: AnyObject], position: NSTextAlignment?)

Setter for expandedAttributedLink with caption, String attributes and optional horizontal alignment as NSTextAlignment.
If the parameter position is nil, the collapse link will be inserted at the end of the text.

```swift
expandableLabel.setLessLinkWith(lessLink: "Close", attributes: [NSForegroundColorAttributeName:UIColor.red], position: nil)
```
<img width="320" src="https://raw.githubusercontent.com/apploft/ExpandableLabel/master/Resources/MoreLessExpand.gif">

##### ellipsis
Set the ellipsis that appears just after the text and before the link.

```swift
expandableLabel.ellipsis = NSAttributedString(string: "...")
```


# License
ExpandableLabel is available under the MIT license. See the LICENSE file for more info.
