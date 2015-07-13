/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit
import QuartzCore

//// MARK: API ////
// MARK: Constants
public extension ____MILRatingCollectionView {
    
    public class Constants {
        
        // MARK: Scrollable View
        /**
        number of cells visible at a time in the view
        even values will show one less cell than selected on startup, due to the view being centered on an initial value
        */
        var numCellsVisible: Int = 5
        
        static let DefaultLowerRangeInt: Int = 1
        static let DefaultUpperRangeInt: Int = 11
        
        var numberRange: NSRange = NSMakeRange(
            ____MILRatingCollectionView.Constants.DefaultLowerRangeInt,
            ____MILRatingCollectionView.Constants.DefaultUpperRangeInt
        )
        
        // MARK: Color
        var circleBackgroundColor = UIColor(red: 218.0/255.0, green: 87.0/255.0, blue: 68.0/255.0, alpha: 1.0)
        var backgroundColor = UIColor.lightGrayColor()
        
        // MARK: Sizing
        var circleDiameterToViewHeightRatio = CGFloat(0.6)
        var minCellWidthInPixels = CGFloat(35.0)
        
        
        // MARK: Fonts (font, size, color)
        var font = "Helvetica"
        var fontSize: CGFloat = 60
        var normalFontColor = UIColor(red: 128/255.0, green: 128/255.0, blue: 128/255.0, alpha: 1.0)
        var highlightedFontColor = UIColor.whiteColor()
        
        /** change this to affect how small / large the fonts become when highlighted and un-highlighted */
        var fontHighlightedAnimationScalingTransform = CGFloat(1.1)
        
        
        // MARK: Animations
        var circleAnimated = true
        var fontAnimated = true
        
        var circleAnimationDuration = NSTimeInterval(0.8)
        var fontAnimationDuration = NSTimeInterval(0.8)
        
        
        // MARK: BEGIN Don't Touch (please)
        static let ErrorString = "An error has occurred within the MILRatingCollectionView."
        var fontUnHighlightedAnimationScalingTransform: CGFloat { return (1 / fontHighlightedAnimationScalingTransform) }
        // MARK: END Don't Touch (please)
        
    }
    
}

/** MARK: Getting current value:
  * STORYBOARD
    * give your view an unique .tag and retrieve it via iteration over self.views in the UIViewController. then do (below)
  * PROGRAMMATICALLY
    * call .currentValue() below
*/
extension ____MILRatingCollectionView {
    
    func currentValue() -> Int? {
        
        let cellView: RatingCollectionViewCell? = _cellViews[_currentlyHighlightedCellIndex]
        return cellView?.number
        
    }
    
    // Old API Support //
    var selectedIndex: Int? { return currentValue() }
    var selectedIndexPath: NSIndexPath? { return NSIndexPath(index: self.selectedIndex ?? 0) }
    
}

//// MARK: END API ////
/** beyond this point all implementation is abstracted away, and bar improvement efforts, doesn't need to be modified */


/** Reusable UIScrollView that acts as a horizontal scrolling number picker */
public class ____MILRatingCollectionView: UIView {
    
    // MARK: Instance Properties
    public var constants: ____MILRatingCollectionView.Constants = ____MILRatingCollectionView.Constants() { didSet { layoutSubviews() } }
    
    private var _scrollView: UIScrollView!
    
    private var _leftCompensationViews: [RatingCollectionViewCell] = []
    private var _innerCellViews: [RatingCollectionViewCell] = []
    private var _rightCompensationViews: [RatingCollectionViewCell] = []
    
    private var _cellViews: [RatingCollectionViewCell] {
        return _leftCompensationViews + _innerCellViews + _rightCompensationViews
    }
    
    private var _currentlyHighlightedCellIndex: Int = 0
    
    private var _dummyOverlayView: UIView!
    
    // exposed to support original API
    var circularView: UIView!
    
    private var _cellWidth: CGFloat {
        return max(
            self.constants.minCellWidthInPixels,
            frame.size.width/CGFloat(self.constants.numCellsVisible)
        )
    }
    
    // MARK: convenience calculations
    private var _size: CGSize { return self.frame.size }
    
    private var _dummyViewFrame: CGRect {
        
        return CGRect(
            x: 0.0,
            y: 0.0,
            width: _size.width,
            height: _size.height
        )
        
    }
    
    private var _circleViewDiameter: CGFloat {
        
        return max(
            _size.height * self.constants.circleDiameterToViewHeightRatio,
            2*self.constants.minCellWidthInPixels
        )
        
    }
    
    private var _circleViewFrame: CGRect {
        
        return CGRect(
            x: _size.width/2,
            y: _size.height/2,
            width: self.circularView.frame.width,
            height: self.circularView.frame.height
        )
        
    }
    
    private var _scrollViewFrame: CGRect {
        return CGRect(origin: CGPointZero, size: _size)
    }
    
    
    // MARK: Instance Methods
    // effectively an init + animation on display
    override public func didMoveToSuperview() {
        
        cleanExistingViews()
        createDummyOverlayView()
        createCircularView()
        addCircularViewToDummyOverlayView()
        configureScrollViewExcludingContentSize()
        configureScrollViewContentSizeAndPopulateScrollView()
        configureInitialScrollViewHighlightedIndex()
        animateCircleToCenter()
        
    }
    
    override public func layoutSubviews() {
        
        cleanExistingViews()
        didMoveToSuperview()
        
    }
    
    private func cleanExistingViews() {
        
        for view in self.subviews {
            
            if let view = view as? UIView {
                view.removeFromSuperview()
            }
            
        }
        
        _leftCompensationViews = []
        _rightCompensationViews = []
        _innerCellViews = []
        
    }
    
    private func createDummyOverlayView() {
        
        _dummyOverlayView = UIView(frame: _dummyViewFrame)
        _dummyOverlayView.backgroundColor = self.constants.backgroundColor
        _dummyOverlayView.userInteractionEnabled = false
        
        self.addSubview(_dummyOverlayView)
        self.sendSubviewToBack(_dummyOverlayView)
        
    }
    
    private func createCircularView() {
        
        let temporaryCircularViewFrame = CGRect(
            x: -_circleViewDiameter/2,
            y: -_circleViewDiameter/2,
            width: _circleViewDiameter,
            height: _circleViewDiameter
        )
        
        self.circularView = UIView(frame: temporaryCircularViewFrame)
        self.circularView.layer.cornerRadius = _circleViewDiameter/2.0
        self.circularView.backgroundColor = self.constants.circleBackgroundColor
        
    }
    
    private func addCircularViewToDummyOverlayView() {
        _dummyOverlayView.addSubview(self.circularView)
    }
    
    /** sets userInteractionEnabled to 'false' initially, see the method 'configureInitialScrollViewHighlightedIndex()' in 'initView()'  */
    private func configureScrollViewExcludingContentSize() {
        
        _scrollView = UIScrollView(frame: _scrollViewFrame)
        
        _scrollView.delegate = self
        _scrollView.showsHorizontalScrollIndicator = false
        _scrollView.userInteractionEnabled = false
        
        self.addSubview(_scrollView)
        
    }
    
    private func configureScrollViewContentSizeAndPopulateScrollView() {
        
        let compensationCountLeftRight = Int(
            floor(
                CGFloat(self.constants.numCellsVisible) / 2.0
            )
        )
        
        // setup useful method variables
        let range = self.constants.numberRange
        let totalItemsCount = range.length + (2*compensationCountLeftRight)
        
        // content size
        _scrollView.contentSize = CGSize(
            width: CGFloat(totalItemsCount) * _cellWidth,
            height: self.frame.height
        )
        
        // generate indices to insert as text
        var indicesToDrawAsText: [Int] = []
        
        for var i = range.location, rangeIndex = 0; i < range.location + range.length; i++ {
            
            indicesToDrawAsText.insert(i, atIndex: rangeIndex)
            rangeIndex++
            
        }
        
        // populate left empty views, then middle, then right empty views
        for var index = 0, runningXOffset = CGFloat(0.0); index < totalItemsCount; index++ {
            
            let newViewFrame = newScrollViewChildViewFrameWithXOffset(runningXOffset)
            let newViewToAdd = RatingCollectionViewCell(frame: newViewFrame, constants: self.constants)
            
            switch index {
                
            case 0 ..< compensationCountLeftRight:
                
                _leftCompensationViews.insert(newViewToAdd, atIndex: index)
                
            case compensationCountLeftRight ..< (totalItemsCount-compensationCountLeftRight):
                
                let innerIndexingCompensation = index - compensationCountLeftRight
                let indexToDraw = indicesToDrawAsText[innerIndexingCompensation]
                
                newViewToAdd.numberLabel.text = "\(indexToDraw)"
                newViewToAdd.number = indexToDraw
                
                _innerCellViews.insert(newViewToAdd, atIndex: innerIndexingCompensation)
                
            case (totalItemsCount-compensationCountLeftRight) ..< totalItemsCount:
                
                let rightIndexingCompensation = index - (totalItemsCount - compensationCountLeftRight)
                _rightCompensationViews.insert(newViewToAdd, atIndex: rightIndexingCompensation)
                
            default: println(Constants.ErrorString)
                
            }
            
            runningXOffset += _cellWidth
            
        }
        
        // add these newly generated views to the scrollview
        for cellView in _cellViews {
            _scrollView.addSubview(cellView)
        }
        
    }
    
    private func newScrollViewChildViewFrameWithXOffset(xOffset: CGFloat) -> CGRect {
        
        return CGRect(
            x: xOffset,
            y: 0.0,
            width: _cellWidth,
            height: self.frame.height
        )
        
    }
    
    private func configureInitialScrollViewHighlightedIndex() {
        
        _currentlyHighlightedCellIndex = 0
        _innerCellViews[_currentlyHighlightedCellIndex].setAsHighlightedCell()
        
    }
    
    private func animateCircleToCenter() {
        
        let moveCircleToCenter: () -> () = {
            self.circularView.center = self._dummyOverlayView.center
        }
        
        if self.constants.circleAnimated {
            
            UIView.animateWithDuration(self.constants.circleAnimationDuration, animations: moveCircleToCenter) {
                (completed: Bool) in self._scrollView.userInteractionEnabled = true
            }
            
        } else {
            
            UIView.animateWithDuration(0.0, animations: moveCircleToCenter) {
                (completed: Bool) in self._scrollView.userInteractionEnabled = true
            }
            
        }
        
    }
    
}


extension ____MILRatingCollectionView: UIScrollViewDelegate {
    
    var centeredX: CGFloat {
        return self.center.x + _scrollView.contentOffset.x
    }
    
    var newCellIndex: Int {
        return Int(
            floor(
                // this "10.0" helps alleviate flooring inaccuracies and results in more-robust responsiveness
                (self.centeredX - _cellWidth/2 + CGFloat(10.0)) / _cellWidth
            )
        )
    }
    
    /**
    Method that recognizes center cell and highlights it while leaving other cells normal
    
    :param: scrollView (should be self)
    */
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        
        // done to prevent recalculating / potential errors
        let newCellIndex = self.newCellIndex
        
        let shouldAttemptHighlightAnotherCell = _currentlyHighlightedCellIndex != newCellIndex
        
        // out of bounds
        let outOfBoundsScrollingLeft = newCellIndex < 0
        let outOfBoundsScrollingRight = (newCellIndex > _cellViews.count-1)
        
        // leftmost entry, rightmost
        let isScrollingPastBoundary = isScrollingPastLastEntry(
            isScrollingRight: (newCellIndex > _currentlyHighlightedCellIndex)
        )
        
        if shouldAttemptHighlightAnotherCell && !outOfBoundsScrollingLeft && !outOfBoundsScrollingRight && !isScrollingPastBoundary {
            
            _cellViews[_currentlyHighlightedCellIndex].setAsNormalCell()
            _cellViews[newCellIndex].setAsHighlightedCell()
            
            _currentlyHighlightedCellIndex = newCellIndex
            
            
            
        } else {
            
            
            
        }
        
    }
    
    private func isScrollingPastLastEntry(#isScrollingRight: Bool) -> Bool {
        
        if newCellIndex > 0 && newCellIndex < _cellViews.count {
            
            let currentlyAccessedCellView = _cellViews[newCellIndex]
            return currentlyAccessedCellView.number == nil
            
        } else {
            return true
        }
        
        
    }
    
    /**
    Reference [1]
    Adjusts scrolling to end exactly on an item
    */
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        var targetCellViewIndex = floor(targetContentOffset.memory.x / _cellWidth)
        
        if ((targetContentOffset.memory.x - floor(targetContentOffset.memory.x / _cellWidth) * _cellWidth) > _cellWidth) {
            targetCellViewIndex++
        }
        
        targetContentOffset.memory.x = targetCellViewIndex * _cellWidth
        
    }
    
}


/**
RatingCollectionViewCell consisting of a number label that varies in size if it is the most centered cell
NOTE: If changing constants below, don't forget to use "digit.0" to avoid CGFloat / Int calculation issues
*/
private final class RatingCollectionViewCell: UIView {
    
    static let InitErrorString = "Use init(coder aDecoder: NSCoder. constants: MILRatingCollectionView.Constants), NOT init without a constants instance."
    
    private var constants: ____MILRatingCollectionView.Constants!
    
    var number: Int?
    var numberLabel: UILabel!
    
    var unHighlightedFontName: String { return "\(self.constants.font)-Medium" }
    var highlightedFontName: String { return "\(self.constants.font)-Bold" }
    
    required init(coder aDecoder: NSCoder) {
        
        fatalError(RatingCollectionViewCell.InitErrorString)
        
    }
    
    init(coder aDecoder: NSCoder, constants: ____MILRatingCollectionView.Constants) {
        
        super.init(coder: aDecoder)
        
        self.constants = constants
        initCell()
        
    }
    
    init(frame: CGRect, constants: ____MILRatingCollectionView.Constants) {
        
        super.init(frame: frame)
        
        self.constants = constants
        initCell()
        
    }
    
    private func initCell() {
        
        numberLabel = UILabel(frame: CGRect(origin: CGPointZero, size: self.frame.size))
        numberLabel.textAlignment = NSTextAlignment.Center
        
        self.addSubview(numberLabel)
        self.setAsNormalCell()
        
    }
    
    /**
    Method to increase number size and animate with a popping effect
    */
    func setAsHighlightedCell() {
        
        let setAsHighlightedAnimation: () -> () = {
            
            let label = self.numberLabel
            
            label.textColor = self.constants.highlightedFontColor
            label.font = UIFont(name: "\(self.highlightedFontName)", size: self.constants.fontSize)
            label.transform = CGAffineTransformScale(label.transform, self.constants.fontHighlightedAnimationScalingTransform, self.constants.fontHighlightedAnimationScalingTransform)
            
        }
        
        if self.constants.fontAnimated {
            UIView.animateWithDuration(self.constants.fontAnimationDuration, animations: setAsHighlightedAnimation)
        } else {
            UIView.animateWithDuration(0.0, animations: setAsHighlightedAnimation)
        }
        
    }
    
    /**
    Returns cells back to their original state and smaller size.
    */
    func setAsNormalCell() {
        
        let setAsUnHighlightedAnimation: () -> () = {
            
            let label = self.numberLabel
            
            label.textColor = self.constants.normalFontColor
            label.font = UIFont(name: "\(self.unHighlightedFontName)", size: self.constants.fontSize)
            label.transform = CGAffineTransformScale(label.transform, self.constants.fontUnHighlightedAnimationScalingTransform, self.constants.fontUnHighlightedAnimationScalingTransform)
            
        }
        
        if self.constants.fontAnimated {
            UIView.animateWithDuration(self.constants.fontAnimationDuration, animations: setAsUnHighlightedAnimation)
        } else {
            UIView.animateWithDuration(0.0, animations: setAsUnHighlightedAnimation)
        }
        
    }
    
}

/** REFERENCES */
// [1] http://www.widecodes.com/7iHmeXqqeU/add-snapto-position-in-a-uitableview-or-uiscrollview.html
