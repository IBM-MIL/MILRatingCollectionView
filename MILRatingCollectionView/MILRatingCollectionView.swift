/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit
import QuartzCore

// TODO: extend init, enable any kind of UIView, make the collectionViewCell do nothing

//private extension UIView {
//
//    /** run the passed closure. if none, resize the first child subview, if any */
//    func setAsNormalCell(#alternativeAnimation: (()->())?, animationDuration: NSTimeInterval) {
//
//        if let alternativeAnimation = alternativeAnimation {
//            UIView.animateWithDuration(animationDuration, animations: alternativeAnimation)
//        } else {
//
//            if let childView = self.subviews.first as? UIView {
//
//                UIView.animateWithDuration(animationDuration) {
//
//                    childView.frame = CGRect(
//                        origin: self.frame.origin,
//                        size: CGSize(
//                            width: self.frame.width/2,
//                            height: self.frame.height/2
//                        )
//                    )
//
//                }
//
//            }
//
//        }
//
//    }
//
//    /** run the passed closure. if none, resize the first child subview, if any */
//    func setAsHighlightedCell(#alternativeAnimation: (()->())?, animationDuration: NSTimeInterval) {
//
//        if let alternativeAnimation = alternativeAnimation {
//            UIView.animateWithDuration(animationDuration, animations: alternativeAnimation)
//        } else {
//
//            if let childView = self.subviews.first as? UIView {
//
//                UIView.animateWithDuration(animationDuration) {
//
//                    childView.frame = CGRect(
//                        origin: self.frame.origin,
//                        size: CGSize(
//                            width: self.frame.width,
//                            height: self.frame.height
//                        )
//                    )
//
//                }
//
//            }
//
//        }
//
//    }
//
//}

/** CollectionViewCell consisting of a number label that varies in size if it is the most centered cell */
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
        
        self.backgroundColor = UIColor.blueColor()
        
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
            
            label.textColor = Constants.HighlightedFontColor
            label.font = UIFont(name: "\(self.unHighlightedFontName)", size: Constants.UnHighlightedFontSize)
            
        }
        
        UIView.animateWithDuration(Constants.AnimationDuration, animations: setAsUnHighlightedAnimation)
        
    }
    
}


/** Reusable UIScrollView that acts as a horizontal scrolling number picker */
final class MILRatingCollectionView: UIView {
    
    /** API */
    private struct Constants {
        
        /// Number of cells visible at a time in the view. Even values will show one less cell than selected on startup, due to the view being centered on an initial value
        static let NumCellsVisible: Int = 5
        
        /// The minimum number of pixels each cell should be. Does not usually need be changed. Only takes effect when the numCellsVisible is set to a value that leaves little room for each cell.
        static let MinCellWidth: CGFloat = 35
        
        /// The size of the circle relative to the size of the cell
        static let CircleDiameterToCellWidthRatio: CGFloat = 2.0
        
        /// The background color of the circle that surrounds the selected item
        static let CircleBackgroundColor = UIColor(red: 218.0/255.0, green: 87.0/255.0, blue: 68.0/255.0, alpha: 1.0)
        
    }
    
    
    // MARK: Instance Properties
    /** Set this to strictly use a range of integers */
    private var _range: NSRange! = NSMakeRange( 0, 11)       // supporting instance variable, don't touch this
    var range: NSRange? {                                   // touch this
        
        get {
            return _range
        }
        
        set {
            _range = newValue
            initView()
        }
        
    }
    
    /**
    Use the method(s)
    - displayViews(views: UIView...)
    - displayViews(views: [UIView] )
    */
    //    private(set) var views: [UIView]?
    
    /** END API */
    
    // scrollView (z = 3, data z = 4)
    private var _scrollView: UIScrollView!
    private var _currentCellIndex: Int = 0
    
    private var _leftCompensationViews: [RatingCollectionViewCell] = []
    private var _innerCellViews: [RatingCollectionViewCell] = []
    private var _rightCompensationViews: [RatingCollectionViewCell] = []
    
    private var _cellViews: [RatingCollectionViewCell] {
        return _leftCompensationViews + _innerCellViews + _rightCompensationViews
    }
    
    // circularView (dummy z = 2, circle z = 3)
    private var _dummyOverlayView: UIView!
    private var _circularView: UIView!
    
    private var _cellWidth: CGFloat {
        return max(Constants.MinCellWidth, frame.size.width/CGFloat(Constants.NumCellsVisible))
    }
    
    
    // MARK: Getters & Setters
    func displayViews(views: UIView...) {
        
        // TODO: implement
        
    }
    
    func displayViews(views: [UIView]) {
        
        // TODO: implement
        
    }
    
    
    // MARK: Instance Methods
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        initView()
        
    }
    
    required init(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        initView()
        
    }
    
    /**
    Externalized to
    - re-configure on device rotation
    - minimize duplicated code
    */
    private func initView() {
        
        println(self.frame)
        
        createDummyOverlayView()
        createCircularView()
        addCircularViewToDummyOverlayView()
        setUpCircularViewAutoLayoutConstraintsBasedOnOverlayBackgroundView()
        configureScrollViewBehindEverythingExcludingContentSize()
        configureScrollViewContentSizeAndPopulateScrollView()
        
        
        
    }
    
    private func configureScrollViewBehindEverythingExcludingContentSize() {
        
        _scrollView = UIScrollView(frame: CGRect(origin: CGPointZero, size: self.frame.size))
        
        _scrollView.delegate = self
        _scrollView.pagingEnabled = true
        _scrollView.showsHorizontalScrollIndicator = false
        _scrollView.backgroundColor = UIColor.brownColor()
        
        self.addSubview(_scrollView)
        
    }
    
    private func createDummyOverlayView() {
        
        let size = self.frame.size
        
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
    
    /** create circularview and fix in the middle of the collectionView background */
    private func createCircularView() {
        
        let circularViewDiameter = min(_cellWidth * Constants.CircleDiameterToCellWidthRatio, self.frame.size.height)
        
        let circularViewFrame = CGRect(
            x: 0.0,
            y: 0.0,
            width: circularViewDiameter,
            height: circularViewDiameter
        )
        
        _circularView = UIView(frame: circularViewFrame)
        _circularView.backgroundColor = Constants.CircleBackgroundColor
        
        roundCircularViewWithDiameter(circularViewDiameter)
        
    }
    
    private func roundCircularViewWithDiameter(diameter: CGFloat) {
        
        let saveCenter = _circularView.center
        let circleOrigin = _circularView.frame.origin
        
        let newCircleFrame = CGRect(
            x: circleOrigin.x,
            y: circleOrigin.y,
            width: diameter,
            height: diameter
        )
        
        _circularView.frame = newCircleFrame
        _circularView.layer.cornerRadius = diameter/2.0
        _circularView.center = saveCenter
        
    }
    
    private func addCircularViewToDummyOverlayView() {
        _dummyOverlayView.addSubview(_circularView)
    }
    
    private func setUpCircularViewAutoLayoutConstraintsBasedOnOverlayBackgroundView() {
        
        _circularView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        let circularViewDiameter = _circularView.frame.width
        
        let constraintsToAdd = [
            
            NSLayoutConstraint(
                item: _circularView,
                attribute: .CenterX,
                relatedBy: .Equal,
                toItem: _dummyOverlayView,
                attribute: .CenterX,
                multiplier: 1,
                constant: 0
            ),
            
            NSLayoutConstraint(
                item: _circularView,
                attribute: .CenterY,
                relatedBy: .Equal,
                toItem: _dummyOverlayView,
                attribute: .CenterY,
                multiplier: 1,
                constant: 0
            ),
            
            NSLayoutConstraint(
                item: _circularView,
                attribute: .Height,
                relatedBy: .Equal,
                toItem:nil,
                attribute: .NotAnAttribute,
                multiplier:1,
                constant: circularViewDiameter),
            
            NSLayoutConstraint(
                item: _circularView,
                attribute: .Width,
                relatedBy: .Equal,
                toItem:nil,
                attribute: .NotAnAttribute,
                multiplier:1,
                constant: circularViewDiameter)
            
        ]
        
        _dummyOverlayView.addConstraints(constraintsToAdd)
        
    }
    
    private func configureScrollViewContentSizeAndPopulateScrollView() {
        
        let compensationCountLeftRight = Int(
            floor(
                CGFloat(Constants.NumCellsVisible) / 2.0
            )
        )
        
        let totalItemsCount = Constants.NumCellsVisible + 2*compensationCountLeftRight
        
        // content size
        _scrollView.contentSize = CGSize(
            width: CGFloat(totalItemsCount) * _cellWidth,
            height: self.frame.height
        )
        
        // populating scrollview
        var runningXOffset: CGFloat = 0.0
        
        for var index = 0; index < totalItemsCount; index++ {
            
            let newViewFrame = CGRect(
                x: runningXOffset,
                y: 0.0,
                width: _cellWidth,
                height: self.frame.height
            )
            
            switch index {
                
            case 0 ..< compensationCountLeftRight:
                
                _leftCompensationViews.insert(
                    RatingCollectionViewCell(frame: newViewFrame),
                    atIndex: index
                )
                
            case compensationCountLeftRight ..< (totalItemsCount-compensationCountLeftRight):
                
                let innerIndexingCompensation = index - compensationCountLeftRight
                
                let newView = RatingCollectionViewCell(frame: newViewFrame)
                newView._numberLabel.text = "\(innerIndexingCompensation)"
                
                _innerCellViews.insert(
                    newView,
                    atIndex: innerIndexingCompensation
                )
                
            case (totalItemsCount-compensationCountLeftRight) ..< totalItemsCount:
                
                let rightIndexingCompensation = index - (totalItemsCount - compensationCountLeftRight)
                
                _rightCompensationViews.insert(
                    RatingCollectionViewCell(frame: newViewFrame),
                    atIndex: rightIndexingCompensation
                )
                
            default:
                println("An error has occurred within the MILRatingCollectionView.")
                
            }
            
            runningXOffset += _cellWidth
            
        }
        
        for cellView in _cellViews {
            _scrollView.addSubview(cellView)
        }
        
    }
    
}


extension MILRatingCollectionView: UIScrollViewDelegate {
    
    /**
    Method that recognizes center cell and highlights it while leaving other cells normal
    
    :param: scrollView (should be self)
    */
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let centeredX = self.center.x + _scrollView.contentOffset.x
        
        // can initially be items in the left compensation views to center our 0th index item in the circle
        let newCellIndex = Int(
            floor(centeredX / _cellWidth) + CGFloat(_leftCompensationViews.count)
        )
        
        if _currentCellIndex != newCellIndex && !(newCellIndex > _cellViews.count-1) {
            
            
            
            //            let setAsHighLightedBlock: ()->() {
            //
            //                if let label = self.subviews.first as? UILabel {
            //
            //
            //
            //                }
            //
            //            }
            
            _cellViews[_currentCellIndex].setAsNormalCell()
            _cellViews[newCellIndex].setAsHighlightedCell()
            
            _currentCellIndex = newCellIndex
            
            
            
        }
        
    }
    
}

///**
//Custom collectionViewFlowLayout in order to have paging on the centered cell
//*/
//class UICollectionViewFlowLayoutCenterItem: UICollectionViewFlowLayout {
//
//    /**
//    Init method that sets default properties for collectionViewlayout
//
//    :param: viewWidth width of screen to base paddings off of.
//
//    :returns: UICollectionViewFlowLayout object
//    */
//    init(viewWidth: CGFloat) {
//        super.init()
//
//        let inset = viewWidth/2 - self.itemSize.width/2
//        self.sectionInset = UIEdgeInsetsMake(0, inset, 0, inset)
//        self.scrollDirection = UICollectionViewScrollDirection.Horizontal
//
//        //Ensure that there is only one row
//        self.minimumInteritemSpacing = CGFloat(UINT16_MAX)
//    }
//
//    required init(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
//
//    // Obj-C version taken from: https://gist.github.com/mmick66/9812223
//    // Method ensures a cell is centered when scrolling has ended
//    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
//
//        let width = self.collectionView!.bounds.size.width
//        let proposedContentOffsetCenterX = proposedContentOffset.x + width * CGFloat(0.5)
//        let proposedRect = self.layoutAttributesForElementsInRect(self.collectionView!.bounds) as! [UICollectionViewLayoutAttributes]
//
//        var candidateAttributes: UICollectionViewLayoutAttributes?
//        for attributes in proposedRect {
//
//            // this ignores header and footer views
//            if attributes.representedElementCategory != UICollectionElementCategory.Cell {
//                continue
//            }
//
//            // set initial value first time through loop
//            if (candidateAttributes == nil) {
//                candidateAttributes = attributes
//                continue
//            }
//
//            // if placement is desired, update candidateAttributes
//            if (fabsf(Float(attributes.center.x) - Float(proposedContentOffsetCenterX)) < fabsf(Float(candidateAttributes!.center.x) - Float(proposedContentOffsetCenterX))) {
//                candidateAttributes = attributes
//            }
//
//        }
//
//        return CGPointMake(candidateAttributes!.center.x - width * CGFloat(0.5), proposedContentOffset.y)
//    }
//
//    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
//        var oldBounds = self.collectionView!.bounds
//        if CGRectGetWidth(oldBounds) != CGRectGetWidth(newBounds) {
//            return true
//        }
//        return false
//    }
//}
