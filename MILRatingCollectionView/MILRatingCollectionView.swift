/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit
import QuartzCore


/**
RatingCollectionViewCell consisting of a number label that varies in size if it is the most centered cell
NOTE: If changing constants below, don't forget to use "digit.0" to avoid CGFloat / Int calculation issues
*/
private final class RatingCollectionViewCell: UIView {
    
    struct Constants {
        
        static let Font = "Helvetica"
        
        static let FontSize: CGFloat = 60
        
        static let FontHighlightedAnimationScalingTransform = CGFloat(1.1)
        
        static let NormalFontColor = UIColor(red: 128/255.0, green: 128/255.0, blue: 128/255.0, alpha: 1.0)
        static let HighlightedFontColor = UIColor.whiteColor()
        
        static let AnimationDuration = NSTimeInterval(0.5)
        
        // don't touch
        static var FontUnHighlightedAnimationScalingTransform: CGFloat { return (1 / FontHighlightedAnimationScalingTransform) }
        
    }
    
    
    var _numberLabel: UILabel!
    
    var unHighlightedFontName: String { return "\(Constants.Font)-Medium" }
    var highlightedFontName: String { return "\(Constants.Font)-Bold" }
    
    
    required init(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        initCell()
        
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        initCell()
        
    }
    
    private func initCell() {
        
        _numberLabel = UILabel(frame: CGRect(origin: CGPointZero, size: self.frame.size))
        _numberLabel.textAlignment = NSTextAlignment.Center
        
        self.addSubview(_numberLabel)
        self.setAsNormalCell()
        
    }
    
    /**
    
    Method to increase number size and animate with a popping effect
    
    */
    func setAsHighlightedCell() {
        
        let setAsHighlightedAnimation: () -> () = {
            
            let label = self._numberLabel
            label.textColor = Constants.HighlightedFontColor
            label.font = UIFont(name: "\(self.highlightedFontName)", size: Constants.FontSize)
            label.transform = CGAffineTransformScale(label.transform, Constants.FontHighlightedAnimationScalingTransform, Constants.FontHighlightedAnimationScalingTransform)
            
        }
        
        UIView.animateWithDuration(Constants.AnimationDuration, animations: setAsHighlightedAnimation)
        
    }
    
    /**
    
    Returns cells back to their original state and smaller size.
    
    */
    func setAsNormalCell() {
        
        let setAsUnHighlightedAnimation: () -> () = {
            
            let label = self._numberLabel
            
            label.textColor = Constants.NormalFontColor
            label.font = UIFont(name: "\(self.unHighlightedFontName)", size: Constants.FontSize)
            label.transform = CGAffineTransformScale(label.transform, Constants.FontUnHighlightedAnimationScalingTransform, Constants.FontUnHighlightedAnimationScalingTransform)
            
        }
        
        UIView.animateWithDuration(Constants.AnimationDuration, animations: setAsUnHighlightedAnimation)
        
    }
    
}


/** 

Reusable UIScrollView that acts as a horizontal scrolling number picker 

**REFERENCES**

1. http://www.widecodes.com/7iHmeXqqeU/add-snapto-position-in-a-uitableview-or-uiscrollview.html

*/
final class MILRatingCollectionView: UIView {
    
    /** 
    
    MARK: API 
    
    */
    class Constants {
        
        /// Movable circle background
        static let Animated = true
        static let AnimationDuration = NSTimeInterval(0.8)
        
        /// Number of cells visible at a time in the view. Even values will show one less cell than selected on startup, due to the view being centered on an initial value
        static let NumCellsVisible: Int = 5
        
        /// The minimum number of pixels each cell should be. Does not usually need be changed. Only takes effect when the numCellsVisible is set to a value that leaves little room for each cell.
        static let MinCellWidth: CGFloat = 35
        
        /// The size of the circle relative to the size of the view's height
        static let CircleDiameterToViewHeightRatio: CGFloat = 0.6
        
        /// The background color of the circle that surrounds the selected item
        static let CircleBackgroundColor = UIColor(red: 218.0/255.0, green: 87.0/255.0, blue: 68.0/255.0, alpha: 1.0)
        
        // dont touch
        static let ErrorString = "An error has occurred within the MILRatingCollectionView."
        static let InitErrorString = "init(coder:) has not been implemented"
        
    }
    
    
    /** Set this to strictly use a range of integers */
    var numberRange: NSRange? {
        
        get {
            return _numberRange
        }
        
        // on set, check if already being displayed before creating redundant text
        set {
            
            _numberRange = newValue
            layoutSubviews()
            
        }
        
    }
    
    /**
    
    **STORYBOARD**
    
    * give your view an unique .tag and retrieve it via iteration over self.views in the UIViewController. then do (below)
    
    **PROGRAMATICALLY**
    
    * call .currentValue() below
    
    */
    var selectedIndex: Int? {
        
        get {
            
            let cellView: RatingCollectionViewCell? = _cellViews[_currentlyHighlightedCellIndex]
            return cellView?._numberLabel.text?.toInt()
            
        }
        
        set {
            
            let isIndexPresentTuple: (isPresent: Bool, scrollLocation: CGPoint) = isIndexPresent(newValue!)
            
            if isIndexPresentTuple.isPresent {
                
                scrollToNewScrollLocation(isIndexPresentTuple.scrollLocation)
                
            }
            
        }
    
    }
    
    var selectedIndexPath: NSIndexPath? {
        
        get {
            
            return NSIndexPath(index: selectedIndex ?? 0)
            
        }
        
        set { selectedIndex = newValue?.indexAtPosition(0) }
        
    }
    
    /** exposed to support original API */
    var circularView: UIView!
    
    
    /** 
    
    MARK: END API
    
    */
    
    
    private var _numberRange: NSRange! = NSMakeRange(1, 11)       // supporting instance variable, don't touch this
    
    private var _scrollView: UIScrollView!
    
    private var _leftCompensationViews: [RatingCollectionViewCell] = []
    private var _innerCellViews: [RatingCollectionViewCell] = []
    private var _rightCompensationViews: [RatingCollectionViewCell] = []
    
    private var _cellViews: [RatingCollectionViewCell] {
        return _leftCompensationViews + _innerCellViews + _rightCompensationViews
    }
    
    private var _currentlyHighlightedCellIndex: Int = 0
    
    private var _dummyOverlayView: UIView!
    
}


/**

MARK: Convenience

loose format here of "general to specific" layout & quick calculations

i.e. frame, then size of inner components, then quick calculations

*/
private extension MILRatingCollectionView {
    
    // MARK: Overall
    var _size: CGSize { return self.frame.size }
    
    
    // MARK: Scroll View
    var _scrollViewFrame: CGRect {
        
        return CGRect(
            origin: CGPointZero,
            size: _size
        )
        
    }
    
    private var centeredX: CGFloat { return self.center.x + _scrollView.contentOffset.x }
    
    private var newCellIndex: Int {
        
        return Int(
            
            floor(
                (self.centeredX - _cellWidth/2) / _cellWidth
            )
            
        )
        
    }
    
    
    // MARK: Dummy View
    var _dummyViewFrame: CGRect {
        
        return CGRect(
            x: 0.0,
            y: 0.0,
            width: _size.width,
            height: _size.height
        )
        
    }
    
    
    // MARK: Circle View
    var _circleViewFrame: CGRect {
        
        return CGRect(
            x: _size.width/2,
            y: _size.height/2,
            width: self.circularView.frame.width,
            height: self.circularView.frame.height
        )
        
    }
    
    var _circleViewDiameter: CGFloat {
        
        return max(
            _size.height * Constants.CircleDiameterToViewHeightRatio,
            2*Constants.MinCellWidth
        )
        
    }
    
    
    // MARK: Cells
    var _cellWidth: CGFloat {
        
        return max(
            Constants.MinCellWidth,
            frame.size.width/CGFloat(Constants.NumCellsVisible)
        )
        
    }
    
}


/**

MARK: Setup

rotation, range-setting, constants-changing --> **layoutSubviews()**

*/
extension MILRatingCollectionView {
    
    override func layoutSubviews() { didMoveToSuperview() }
    
    // effectively an init + animation on display
    override func didMoveToSuperview() {
        
        cleanExistingViews()
        createDummyOverlayView()
        createCircularView()
        addCircularViewToDummyOverlayView()
        configureScrollViewExcludingContentSize()
        configureScrollViewContentSizeAndPopulateScrollView()
        configureInitialScrollViewHighlightedIndex()
        animateCircleToCenter()
        
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
        _dummyOverlayView.backgroundColor = UIColor.blueColor()
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
        self.circularView.backgroundColor = Constants.CircleBackgroundColor
        
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
                CGFloat(Constants.NumCellsVisible) / 2.0
            )
        )
        
        let totalItemsCount = self.numberRange!.length + 2*compensationCountLeftRight
        
        // content size
        _scrollView.contentSize = CGSize(
            width: CGFloat(totalItemsCount) * _cellWidth,
            height: self.frame.height
        )
        
        // populating scrollview
        var runningXOffset: CGFloat = 0.0
        var newViewToAdd: RatingCollectionViewCell!
        
        // generate indices to insert as text
        var indicesToDrawAsText: [Int] = []
        var rangeIndex = 0
        
        let range = self.numberRange!
        for var i = range.location; i < range.location + range.length; i++ {
            
            indicesToDrawAsText.insert(i, atIndex: rangeIndex)
            rangeIndex++
            
        }
        
        // populate left empty views, then middle, then right empty views
        for var index = 0; index < totalItemsCount; index++ {
            
            let newViewFrame = newScrollViewChildViewFrameWithXOffset(runningXOffset)
            newViewToAdd = RatingCollectionViewCell(frame: newViewFrame)
            
            switch index {
                
            case 0 ..< compensationCountLeftRight:
                
                _leftCompensationViews.insert(newViewToAdd, atIndex: index)
                
            case compensationCountLeftRight ..< (totalItemsCount-compensationCountLeftRight):
                
                let innerIndexingCompensation = index - compensationCountLeftRight
                newViewToAdd._numberLabel.text = "\(indicesToDrawAsText[innerIndexingCompensation])"
                _innerCellViews.insert(newViewToAdd, atIndex: innerIndexingCompensation)
                
            case (totalItemsCount-compensationCountLeftRight) ..< totalItemsCount:
                
                let rightIndexingCompensation = index - (totalItemsCount - compensationCountLeftRight)
                _rightCompensationViews.insert(newViewToAdd, atIndex: rightIndexingCompensation)
                
            default:
                println(Constants.ErrorString)
                
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
        
        if Constants.Animated {
            
            UIView.animateWithDuration(Constants.AnimationDuration, animations: moveCircleToCenter) {
                (completed: Bool) in self._scrollView.userInteractionEnabled = true
            }
            
        } else {
            
            UIView.animateWithDuration(0.0, animations: moveCircleToCenter) {
                (completed: Bool) in self._scrollView.userInteractionEnabled = true
            }
            
        }
        
    }
    
}


/**

MARK: Checking Current State

*/
extension MILRatingCollectionView {
    
    private func isIndexPresent(index: Int) -> (isPresent: Bool, scrollLocation: CGPoint) {
        
        var returnTuple: (isPresent: Bool, scrollLocation: CGPoint) = (isPresent: false, scrollLocation: CGPointZero)
        
        /**
        
        in Swift 2.0, the syntax would be
        
            for (index, viewCell) in array.enumerate()
        
        whereas in Swift 1.2
        
            for (index, viewCell) in enumerate(array)
        
        in this case, we'll stick to an "index," but the desire for some syntactic sugar was there. :)
        
        */
        for i in 0 ..< _innerCellViews.count {
            
            let ratingCollectionViewCell = _innerCellViews[i]
            
            let label = ratingCollectionViewCell._numberLabel
            
            if label != nil {
                
                if let numberValue = label.text?.toInt() {
                    
                    if index == numberValue {
                        
                        returnTuple.isPresent = true
                        returnTuple.scrollLocation = CGPoint(
                            x: CGFloat(i + _leftCompensationViews.count) * _cellWidth + 0.5 * _cellWidth - _scrollView.center.x,
                            y: 0.0
                        )
                        
                    }
                    
                }
                
            }
            
        }
        
        return returnTuple
        
    }
    
}


/**

MARK: UIScrollViewDelegate

*/
extension MILRatingCollectionView: UIScrollViewDelegate {
    
    /**
    
    Method that recognizes center cell and highlights it while leaving other cells normal
    
    :param: scrollView (should be self)
    
    */
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        // done to prevent recalculating / potential errors
        let newCellIndex = self.newCellIndex
        
        let shouldHighlightAnotherCell = _currentlyHighlightedCellIndex != newCellIndex
        let outOfBoundsScrollingLeft = newCellIndex < 0
        let outOfBoundsScrollingRight = (newCellIndex > _cellViews.count-1)
        
        if shouldHighlightAnotherCell && !outOfBoundsScrollingLeft && !outOfBoundsScrollingRight {
            
            _cellViews[_currentlyHighlightedCellIndex].setAsNormalCell()
            _cellViews[newCellIndex].setAsHighlightedCell()
            _currentlyHighlightedCellIndex = newCellIndex
            
        }
        
    }
    
    /**
    
    Reference [1]
    
    Adjusts scrolling to end exactly on an item
    
    */
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        var targetCellViewIndex = floor(targetContentOffset.memory.x / _cellWidth)
        
        if ((targetContentOffset.memory.x - floor(targetContentOffset.memory.x / _cellWidth) * _cellWidth) > _cellWidth) {
            targetCellViewIndex++
        }
        
        targetContentOffset.memory.x = targetCellViewIndex * _cellWidth
        
    }
    
    /**

    called when the currently selected index is programmatically set
    
    */
    private func scrollToNewScrollLocation(newLocation: CGPoint) {
        
        // overcompensate in scrolling to deal with floor / round inaccuracies
        let compensationAmount = CGFloat(0.0)
        
        let isScrollingRight = (newLocation.x > _scrollView.contentOffset.x)
        
        var newContentOffset = CGPoint(
            x: isScrollingRight ? (newLocation.x + compensationAmount) : (newLocation.x - compensationAmount),
            y: 0.0
        )
        
        _scrollView.setContentOffset(newContentOffset, animated: true)
        
    }
    
}
