# ExpandableLabel
ExpandableLabel is a simple UILabel subclass that shows a tappable link if the content doesn't fit the specified number of lines. If touched, the label will expand to show the entire content.

<img src="">

# Installation
Install via cocoapods by adding this to your Podfile:

```
pod "ExpandableLabel"
```

# Usage
Using ExpandableLabel is very simple. In your storyboard, set the custom class of your UILabel to ExpandableLabel and set the desired number of lines (for the collapsed state):

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

##### ellipsis
Set the ellipsis that appears just after the text and before the link.

```swift
expandableLabel.ellipsis = NSAttributedString(string: "...")
```


# License
ExpandableLabel is available under the MIT license. See the LICENSE file for more info.