# SwiftUnistroke

[![CI Status](http://img.shields.io/travis/Daniele Margutti/SwiftUnistroke.svg?style=flat)](https://travis-ci.org/Daniele Margutti/SwiftUnistroke)
[![Version](https://img.shields.io/cocoapods/v/SwiftUnistroke.svg?style=flat)](http://cocoapods.org/pods/SwiftUnistroke)
[![License](https://img.shields.io/cocoapods/l/SwiftUnistroke.svg?style=flat)](http://cocoapods.org/pods/SwiftUnistroke)
[![Platform](https://img.shields.io/cocoapods/p/SwiftUnistroke.svg?style=flat)](http://cocoapods.org/pods/SwiftUnistroke)

## Description
SwiftUnistroke is a pure Swift 2 implementation of the $1 Unistroke Algorithm developed by Jacob Wobbrock, Andy Wilson and Yang Li.

The $1 Unistroke Recognizer is a 2-D single-stroke recognizer designed for rapid prototyping of gesture-based user interfaces.

In machine learning terms, $1 is an instance-based nearest-neighbor classifier with a Euclidean scoring function, i.e., a geometric template matcher.

Despite its simplicity, $1 requires very few templates to perform well and is only about 100 lines of code, making it easy to deploy. An optional enhancement called Protractor improves $1's speed.

A more detailed description of the algorithm is available both on [official project paper](http://faculty.washington.edu/wobbrock/pubs/uist-07.01.pdf) and on my [blog's article here](http://danielemargutti.com/1-recognizer-in-swift-2/).

This library also contain an example project which demostrate how the algorithm works with a set of loaded templates; extends this library is pretty easy and does not involve any machine learning stuff.
Other languages implementation can be [found here](https://depts.washington.edu/aimgroup/proj/dollar/).

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
- Mac OS X 10.10+ or iOS 8+
- Swift 2+

## Installation

SwiftUnistroke is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SwiftUnistroke"
```

## Author

Daniele Margutti, me@danielemargutti.com

## License

SwiftUnistroke is available under the MIT license. See the LICENSE file for more info.
