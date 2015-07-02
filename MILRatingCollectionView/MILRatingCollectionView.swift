/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit
import QuartzCore


/** RatingCollectionViewCell consisting of a number label that varies in size if it is the most centered cell */
private final class RatingCollectionViewCell: UIView {
    
    struct Constants {
        
        static let Font = "Helvetica"
        
        static let UnHighlightedFontSize: CGFloat = 30
        static let HighlightedFontSize: CGFloat = 65
        
        static let NormalFontColor = UIColor(red: 128/255.0, green: 128/255.0, blue: 128/255.0, alpha: 1.0)
        static let HighlightedFontColor = UIColor.whiteColor()
        
        static let AnimationDuration = NSTimeInterval(0.25)
        
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
        
        _numberLabel.textColor = Constants.NormalFontColor
        _numberLabel.font = UIFont(name: unHighlightedFontName, size: Constants.UnHighlightedFontSize)
        _numberLabel.textAlignment = NSTextAlignment.Center
        
        self.addSubview(_numberLabel)
        
    }
    
    /**
    Method to increase number size and animate with a popping effect
    */
    func setAsHighlightedCell() {
        
        let setAsHighlightedAnimation: () -> () = {
            
            let label = self._numberLabel
            
            label.textColor = Constants.HighlightedFontColor
            label.font = UIFont(name: "\(self.highlightedFontName)", size: Constants.HighlightedFontSize)
            
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
            label.font = UIFont(name: "\(self.unHighlightedFontName)", size: Constants.UnHighlightedFontSize)
            
        }
        
        UIView.animateWithDuration(Constants.AnimationDuration, animations: setAsUnHighlightedAnimation)
        
    }
    
}


/** Reusable UIScrollView that acts as a horizontal scrolling number picker */
final class MILRatingCollectionView: UIView {
    
    /** API */
    private struct Constants {
        
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
        
    }
    
    
    // MARK: Instance Properties
    /** Set this to strictly use a range of integers */
    private var _range: NSRange! = NSMakeRange(1, 11)       // supporting instance variable, don't touch this
    var range: NSRange? {                                   // touch this
        
        get {
            return _range
        }
        
        // on set, check if already being displayed before creating redundant text
        set {
            
            _range = newValue
            initView()
        }
        
    }
    
    /** END API */
    
    
    // TODO: implement, screen points vs. pixels is buggy (Swift issue?)
    // coder (storyboard) vs. programmatic creation
    //    private var _storyboardUsed = false
    //    var adjustedSize: CGSize {
    //
    //        if _storyboardUsed {
    //
    //            let screen = UIScreen.mainScreen()
    //            let coordinateSpace = screen.coordinateSpace
    //            return self.superview!.convertRect(self.frame, fromCoordinateSpace: coordinateSpace).size
    //
    //        } else {
    //            return self.frame.size
    //        }
    //
    //    }
    
    private var _scrollView: UIScrollView!
    
    private var _leftCompensationViews: [RatingCollectionViewCell] = []
    private var _innerCellViews: [RatingCollectionViewCell] = []
    private var _rightCompensationViews: [RatingCollectionViewCell] = []
    
    private var _cellViews: [RatingCollectionViewCell] {
        return _leftCompensationViews + _innerCellViews + _rightCompensationViews
    }
    
    private var _currentlyHighlightedCellIndex: Int = 0
    
    private var _dummyOverlayView: UIView!
    private var _circularView: UIView!
    
    private var _cellWidth: CGFloat {
        return max(
            Constants.MinCellWidth,
            frame.size.width/CGFloat(Constants.NumCellsVisible)
        )
    }
    
    
    // MARK: Instance Methods
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        initView()
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
    Externalized to
    - re-configure on device rotation / range property set
    - minimize duplicated code
    */
    private func initView() {
        
        cleanExistingViews()
        createDummyOverlayView()
        createCircularView()
        addCircularViewToDummyOverlayView()
        configureScrollViewExcludingContentSize()
        configureScrollViewContentSizeAndPopulateScrollView()
        configureInitialScrollViewHighlightedIndex()
        
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
        
        var size: CGSize { return self.frame.size }
        
        let dummyBackgroundViewFrame = CGRect(
            x: 0.0,
            y: 0.0,
            width: size.width,
            height: size.height
        )
        
        _dummyOverlayView = UIView(frame: dummyBackgroundViewFrame)
        _dummyOverlayView.backgroundColor = UIColor.brownColor()
        _dummyOverlayView.userInteractionEnabled = false
        
        self.addSubview(_dummyOverlayView)
        self.sendSubviewToBack(_dummyOverlayView)
        
    }
    
    private func createCircularView() {
        
        let circularViewDiameter = max(self.frame.height * Constants.CircleDiameterToViewHeightRatio, 2*Constants.MinCellWidth)
        
        let temporaryCircularViewFrame = CGRect(
            x: -circularViewDiameter/2,
            y: -circularViewDiameter/2,
            width: circularViewDiameter,
            height: circularViewDiameter
        )
        
        _circularView = UIView(frame: temporaryCircularViewFrame)
        _circularView.layer.cornerRadius = circularViewDiameter/2.0
        _circularView.backgroundColor = Constants.CircleBackgroundColor
        
    }
    
    private func addCircularViewToDummyOverlayView() {
        _dummyOverlayView.addSubview(_circularView)
    }
    
    /** sets userInteractionEnabled to 'false' initially, see the method 'configureInitialScrollViewHighlightedIndex()' in 'initView()'  */
    private func configureScrollViewExcludingContentSize() {
        
        _scrollView = UIScrollView(frame: CGRect(origin: CGPointZero, size: self.frame.size))
        
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
        
        let totalItemsCount = _range.length + 2*compensationCountLeftRight
        
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
        
        for var i = _range.location; i < _range.location + _range.length; i++ {
            
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
                println("An error has occurred within the MILRatingCollectionView.")
                
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
    
    // MARK: animation on display
    override func didMoveToSuperview() {
        
        let moveCircleToCenter: () -> () = {
            self._circularView.center = self._dummyOverlayView.center
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


extension MILRatingCollectionView: UIScrollViewDelegate {
    
    var centeredX: CGFloat {
        return self.center.x + _scrollView.contentOffset.x
    }
    
    var newCellIndex: Int {
        return Int(
            floor(
                (self.centeredX - _cellWidth/2) / _cellWidth
            )
        )
    }
    
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
    
}

/** REFERENCES */
// [1] http://www.widecodes.com/7iHmeXqqeU/add-snapto-position-in-a-uitableview-or-uiscrollview.html
