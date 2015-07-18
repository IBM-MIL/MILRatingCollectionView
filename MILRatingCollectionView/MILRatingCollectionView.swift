/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit
import QuartzCore


//numberRange: NSRange

/**

MARK: Constants

*/
extension MILRatingCollectionView {
    
    /**
    
    MARK: API
    
    */
    public class Constants {
        
        /** Set this to strictly use a range of integers */
        var numberRange: NSRange? {
            get { return _parent?._numberRange }
            set { _parent?._numberRange = newValue }
        }
        
        var selectedIndex: Int? {
            get { return _parent?._selectedIndex }
            set { _parent?._selectedIndex = newValue }
        }
        
        var selectedIndexPath: NSIndexPath? {
            get { return NSIndexPath(index: selectedIndex ?? 0) }
            set { selectedIndex = newValue?.indexAtPosition(0) }
        }
        
        
        // MARK: Scrollable View
        /**
        number of cells visible at a time in the view
        even values will show one less cell than selected on startup, due to the view being centered on an initial value
        */
        var numCellsVisible: Int = 5 { didSet { update() } }
        
        static let DefaultLowerRangeInt: Int = 1
        static let DefaultUpperRangeInt: Int = 11
        
        
        // MARK: Color
        var circleBackgroundColor = UIColor(red: 218.0/255.0, green: 87.0/255.0, blue: 68.0/255.0, alpha: 1.0) { didSet {  _parent?.adjustCircleColor() } }
        
        var backgroundColor = UIColor.lightGrayColor() { didSet { _parent?.adjustBackgroundColor() } }
        
        
        // MARK: Sizing
        var circleDiameterToViewHeightRatio = CGFloat(0.6) { didSet { update() } }
        
        var minCellWidthInPixels = CGFloat(35.0) { didSet { update() } }
        
        
        // MARK: Fonts (font, size, color)
        var font = "Helvetica" { didSet { update() } }
        
        var fontSize: CGFloat = 60 { didSet { update() } }
        
        var normalFontColor = UIColor(red: 128/255.0, green: 128/255.0, blue: 128/255.0, alpha: 1.0) { didSet { update() } }
        
        var highlightedFontColor = UIColor.whiteColor() { didSet { update() } }
        
        /** change this to affect how small / large the fonts become when highlighted and un-highlighted */
        var fontHighlightedAnimationScalingTransform = CGFloat(1.1) { didSet { update() } }
        
        
        // MARK: Animations
        var circleAnimated = true
        var fontAnimated = true { didSet { update() } }
        
        var circleAnimationDuration = NSTimeInterval(0.8)
        var fontAnimationDuration = NSTimeInterval(0.8)
        
        /**

        END API

        */
        
        // MARK: Don't Touch (please)
        static let ErrorString = "An error has occurred within the MILRatingCollectionView."
        var fontUnHighlightedAnimationScalingTransform: CGFloat { return (1 / fontHighlightedAnimationScalingTransform) }
        
        init(parent: MILRatingCollectionView!) { _parent = parent }
        
        private weak var _parent: MILRatingCollectionView?
        private func update() {  _parent?.layoutSubviews() }
        
    }
    
}


/** 

Reusable UIScrollView that acts as a horizontal scrolling number picker 

**REFERENCES**

1. http://www.widecodes.com/7iHmeXqqeU/add-snapto-position-in-a-uitableview-or-uiscrollview.html

*/
public final class MILRatingCollectionView: UIView {
    
    public var constants: MILRatingCollectionView.Constants! {
        didSet { layoutSubviews() }
    }
    
    private var _circularView: UIView!
    
    private var _numberRange: NSRange! = NSMakeRange(
        MILRatingCollectionView.Constants.DefaultLowerRangeInt,
        MILRatingCollectionView.Constants.DefaultUpperRangeInt
        ) {
        didSet { layoutSubviews() }
    }
    
    private var _scrollView: UIScrollView!
    
    private var _leftCompensationViews: [RatingCollectionViewCell] = []
    private var _innerCellViews: [RatingCollectionViewCell] = []
    private var _rightCompensationViews: [RatingCollectionViewCell] = []
    
    private var _cellViews: [RatingCollectionViewCell] {
        return _leftCompensationViews + _innerCellViews + _rightCompensationViews
    }
    
    private var _currentlyHighlightedCellIndex: Int = 0
    
    private var _dummyOverlayView: UIView!
    
    
    var nilConstants: Bool { return self.constants == nil }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        if nilConstants { self.constants = MILRatingCollectionView.Constants(parent: self) }
        
    }
    
    public required init(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        if nilConstants { self.constants = MILRatingCollectionView.Constants(parent: self) }
        
    }
    
}


/**

MARK: Convenience

* Sizes

* Property Change Handlers

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
    
    private func adjustBackgroundColor() {
        
        if self._dummyOverlayView != nil {
            _dummyOverlayView.backgroundColor = self.constants.backgroundColor
        }
        
    }
    
    
    // MARK: Circle View
    var _circleViewFrame: CGRect {
        
        return CGRect(
            x: _size.width/2,
            y: _size.height/2,
            width: self._circularView.frame.width,
            height: self._circularView.frame.height
        )
        
    }
    
    var _circleViewDiameter: CGFloat {
        
        return max(
            _size.height * constants.circleDiameterToViewHeightRatio,
            2 * constants.minCellWidthInPixels
        )
        
    }
    
    private func adjustCircleColor() {
        
        if self._circularView != nil {
            _circularView.backgroundColor = self.constants.circleBackgroundColor
        }
        
    }
    
    
    // MARK: Cells
    var _cellWidth: CGFloat {
        
        return max(
            constants.minCellWidthInPixels,
            frame.size.width/CGFloat(constants.numCellsVisible)
        )
        
    }
    
    private var _selectedIndex: Int? {
        
        get {
            
            let cellView: RatingCollectionViewCell? = _cellViews[_currentlyHighlightedCellIndex]
            return cellView?._numberLabel.text?.toInt()
            
        }
        
        set {
            
            /** declares the new type, "isPresentTuple" */
            typealias isPresentTuple = (isPresent: Bool, scrollLocation: CGPoint)
            
            let isIndexPresentTuple: isPresentTuple = isIndexPresent(newValue!)
            
            if isIndexPresentTuple.isPresent {
                scrollToNewScrollLocation(isIndexPresentTuple.scrollLocation)
            }
            
        }
        
    }
    
}


/**

MARK: Setup

rotation, range-setting, constants-changing --> **layoutSubviews()**

*/
extension MILRatingCollectionView {
    
    override public func layoutSubviews() { didMoveToSuperview() }
    
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
        
        _circularView = UIView(frame: temporaryCircularViewFrame)
        _circularView.layer.cornerRadius = _circleViewDiameter/2.0
        _circularView.backgroundColor = constants.circleBackgroundColor
        
    }
    
    private func addCircularViewToDummyOverlayView() {
        _dummyOverlayView.addSubview(self._circularView)
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
        
        let totalItemsCount = self.constants.numberRange!.length + 2 * compensationCountLeftRight
        
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
        
        let range = self.constants.numberRange!
        for var i = range.location; i < range.location + range.length; i++ {
            
            indicesToDrawAsText.insert(i, atIndex: rangeIndex)
            rangeIndex++
            
        }
        
        // populate left empty views, then middle, then right empty views
        for var index = 0; index < totalItemsCount; index++ {
            
            let newViewFrame = newScrollViewChildViewFrameWithXOffset(runningXOffset)
            newViewToAdd = RatingCollectionViewCell(frame: newViewFrame, parent: self)
            
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
            self._circularView.center = self._dummyOverlayView.center
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
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        
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
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
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


/**

RatingCollectionViewCell consisting of a number label that varies in size if it is the most centered cell

NOTE: If changing constants below, don't forget to use "digit.0" to avoid CGFloat / Int calculation issues

*/
extension MILRatingCollectionView {
    
    private final class RatingCollectionViewCell: UIView {
        
        var _parentConstants: MILRatingCollectionView.Constants!
        
        var _numberLabel: UILabel!
        
        var unHighlightedFontName: String { return "\(_parentConstants.font)-Medium" }
        var highlightedFontName: String { return "\(_parentConstants.font)-Bold" }
        
        required init(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
        
        init(frame: CGRect, parent: MILRatingCollectionView) {
            
            super.init(frame: frame)
            
            _parentConstants = parent.constants
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
                label.textColor = self._parentConstants.highlightedFontColor
                label.font = UIFont(name: "\(self.highlightedFontName)", size: self._parentConstants.fontSize)
                label.transform = CGAffineTransformScale(label.transform, self._parentConstants.fontHighlightedAnimationScalingTransform, self._parentConstants.fontHighlightedAnimationScalingTransform)
                
            }
            
            UIView.animateWithDuration(_parentConstants.fontAnimationDuration, animations: setAsHighlightedAnimation)
            
        }
        
        /**
        
        Returns cells back to their original state and smaller size.
        
        */
        func setAsNormalCell() {
            
            let setAsUnHighlightedAnimation: () -> () = {
                
                let label = self._numberLabel
                
                label.textColor = self._parentConstants.normalFontColor
                label.font = UIFont(name: "\(self.unHighlightedFontName)", size: self._parentConstants.fontSize)
                label.transform = CGAffineTransformScale(label.transform, self._parentConstants.fontUnHighlightedAnimationScalingTransform, self._parentConstants.fontUnHighlightedAnimationScalingTransform)
                
            }
            
            UIView.animateWithDuration(_parentConstants.fontAnimationDuration, animations: setAsUnHighlightedAnimation)
            
        }
        
    }
 
}
