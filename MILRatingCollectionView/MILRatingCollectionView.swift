/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit
import QuartzCore

/**
Reusable CollectionView that acts as a horizontal scrolling number picker
*/
class MILRatingCollectionView: UICollectionView {
    
    /// Number of cells visible at a time in the view. Even values will show one less cell than selected on startup, due to the view being centered on an initial value
    let numCellsVisible: CGFloat = 5
    
    /// The minimum number of pixels each cell should be. Does not usually need be changed. Only takes effect when the numCellsVisible is set to a value that leaves little room for each cell.
    let minCellWidth: CGFloat = 35
    /// The size of the circle relative to the size of the cell
    let circleDiameterToCellWidthRatio: CGFloat = 2.0
    
    /// The background color of the circle that surrounds the selected item
    let circleBackgroundColor = UIColor(red: 218.0/255.0, green: 87.0/255.0, blue: 68.0/255.0, alpha: 1.0)
    
    var dummyBackgroundView: UIView!
    var circularView: UIView!
    var selectedIndexPath: NSIndexPath?
    var ratingCellID = "ratingCell"
    var centerIsSet = false
    
    /// The width of each individual cell which is computed by dividing the width of the view by the number of cells desired to be visible. The minimum cell width is used if the computed value is less than it.
    var cellWidth: CGFloat {
        get {
            return max(minCellWidth,frame.size.width/numCellsVisible)
        }
    }

    private var currentNumberRange: NSRange = NSMakeRange(0,11)
    /// The range of the collectionView, location is the starting number, length is the number of elements
    var numberRange: NSRange {
        set(value) {
            currentNumberRange = value
            selectedIndexPath = NSIndexPath(forRow: (currentNumberRange.length - currentNumberRange.location)/2, inSection: 0)
        }
        get {
            return currentNumberRange
        }
    }

    /// Private delegate so callbacks in this class will be called before any child class
    private var actualDelegate: UICollectionViewDelegate?
    /// Private datasource so callbacks in this class will be called before any child class
    private var actualDataSource: UICollectionViewDataSource?
    
    /// custom delegate property accessible to external classes
    var preDelegate: UICollectionViewDelegate? {
        set(newValue) {
            self.actualDelegate = newValue
            //super.delegate = self
        }
        get {
            return self.actualDelegate
        }
    }
    
    /// custom datasource property accessible to external classes
    var preDataSource: UICollectionViewDataSource? {
        set(newValue) {
            self.actualDataSource = newValue
            //super.dataSource = self
        }
        get {
            return self.actualDataSource
        }
    }
    
    // Init method called programmaticly
    convenience init(frame: CGRect) {
        self.init(frame: frame)
        initView()
    }
    
    // Init method called from storyboard
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // Allows cells to increase in size on larger devices
        //var totalCellWidth = collectionView.frame.size.width - self.totalHorizontalSpacing
        
        // Using available cell width, divide by 2 for single cell width and then multiple by aspect ratio for height
        var size = CGSizeMake(self.cellWidth, collectionView.frame.size.height)
        return size
    }
    
    /**
    MILRatingCollectionView set up method, initializes background and collectionView properties.
    */
    func initView() {
        super.delegate = self
        super.dataSource = self
        
        self.collectionViewLayout = UICollectionViewFlowLayoutCenterItem(viewWidth: UIScreen.mainScreen().bounds.size.width)
        self.showsHorizontalScrollIndicator = false
        self.registerClass(RatingCollectionViewCell.self, forCellWithReuseIdentifier: ratingCellID)
        // create circularview and fix in the middle of the collectionView background
        let circularViewDiameter = min(cellWidth * circleDiameterToCellWidthRatio,self.frame.size.height)
        circularView = UIView(frame: CGRectMake(0, 0, circularViewDiameter,circularViewDiameter))
        circularView.backgroundColor = circleBackgroundColor
        self.setRoundedViewToDiameter(circularView, diameter: circularView.frame.size.height)
        dummyBackgroundView = UIView(frame: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height))
        dummyBackgroundView.addSubview(circularView)
        self.backgroundView = dummyBackgroundView
        
        setUpAutoLayoutConstraints(circularViewDiameter)
    }
    
    /**
    Method to round corners enough to make a circle based on diameter.
    
    :param: view     UIView to circlefy
    :param: diameter the desired diameter of your view
    */
    func setRoundedViewToDiameter(view: UIView, diameter: CGFloat) {
        
        let saveCenter = view.center
        let newFrame = CGRectMake(view.frame.origin.x, view.frame.origin.y, diameter, diameter)
        view.frame = newFrame
        view.layer.cornerRadius = diameter / 2.0
        view.center = saveCenter
        
    }
    
}


extension MILRatingCollectionView: UICollectionViewDelegate {
    
}


extension MILRatingCollectionView: UICollectionViewDataSource {
    
    // number of items based on number range set by developer
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentNumberRange.length - currentNumberRange.location
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell: RatingCollectionViewCell?
        
        // if preDataSource not set by developer, create cell like normal
        if let ds = preDataSource {
            cell = ds.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as? RatingCollectionViewCell
        } else {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(ratingCellID, forIndexPath: indexPath) as? RatingCollectionViewCell
        }
        
        cell!.numberLabel.text = "\(indexPath.row + currentNumberRange.location)" // offset to start at 1
        
        // sets an initial highlighted cell, only true once
        if !centerIsSet && indexPath == selectedIndexPath {
            
            cell!.setAsHighlightedCell()
            centerIsSet = true
            
        }
        
        return cell!
        
    }
    
}


extension MILRatingCollectionView: UIScrollViewDelegate {
    
    /**
    Method replicating the functionality of indexPathForItemAtPoint(), which was not working with the custom flow layout
    
    :param: point center point to find most centered cell
    
    :returns: UICollectionViewLayoutAttributes of the centered cell
    */
    func grabCellAttributesAtPoint(point: CGPoint) -> UICollectionViewLayoutAttributes? {
        
        let visible = self.indexPathsForVisibleItems()
        
        for paths in visible {
            var layoutAttributes = self.layoutAttributesForItemAtIndexPath(paths as! NSIndexPath)
            
            // true when center point is within a cell's frame
            if CGRectContainsPoint(layoutAttributes!.frame, point) {
                return layoutAttributes!
                
            }
        }
        return nil
    }
    
    /**
    Method that recognizes center cell and highlights it while leaving other cells normal
    
    :param: scrollView scrollView built into the UICollectionView
    */
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        // Get centered point within collectionView contentSize, y value not crucial, just needs to always be in center
        var centerPoint = CGPointMake(self.center.x + self.contentOffset.x,
            self.contentSize.height / 2)
        
        if var attributes = grabCellAttributesAtPoint(centerPoint) {
            
            // true when center cell has changed, revert old center cell to normal cell
            if selectedIndexPath != attributes.indexPath {
                if let oldPath = selectedIndexPath {
                    if var previousCenterCell = self.cellForItemAtIndexPath(oldPath) as? RatingCollectionViewCell {
                        previousCenterCell.setAsNormalCell()
                    }
                }
                
                // make current center cell a highlighted cell
                var cell = self.cellForItemAtIndexPath(attributes.indexPath) as! RatingCollectionViewCell
                cell.setAsHighlightedCell()
                selectedIndexPath = attributes.indexPath
                
            }
        }
    }
    
    /**
    Autolayout constraints for the circular background view
    */
    func setUpAutoLayoutConstraints(circularViewDiameter: CGFloat) {
        self.circularView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        self.dummyBackgroundView.addConstraint(NSLayoutConstraint(
            item:self.circularView, attribute:.CenterX,
            relatedBy:.Equal, toItem:self.dummyBackgroundView,
            attribute:.CenterX, multiplier:1, constant:0))
        self.dummyBackgroundView.addConstraint(NSLayoutConstraint(
            item:self.circularView, attribute:.CenterY,
            relatedBy:.Equal, toItem:self.dummyBackgroundView,
            attribute:.CenterY, multiplier:1, constant:0))
        self.dummyBackgroundView.addConstraint(NSLayoutConstraint(
            item:self.circularView, attribute:.Height,
            relatedBy:.Equal, toItem:nil,
            attribute:.NotAnAttribute, multiplier:1, constant:circularViewDiameter))
        self.dummyBackgroundView.addConstraint(NSLayoutConstraint(
            item:self.circularView, attribute:.Width,
            relatedBy:.Equal, toItem:nil,
            attribute:.NotAnAttribute, multiplier:1, constant:circularViewDiameter))
    }
    
}


/**
CollectionViewCell consisting of a number label that varies in size if it is the most centered cell
*/
class RatingCollectionViewCell: UICollectionViewCell {
    
    /// Font face to use for each item in the range
    let selectedFont = "Helvetica"
    /// The font color for each unselected item in the range
    let normalFontColor = UIColor(red: 128/255.0, green: 128/255.0, blue: 128/255.0, alpha: 1.0)
    /// The font color for the selected item in the range
    let highlightedFontColor = UIColor.whiteColor()
    
    var numberLabel: UILabel!
    
    /**
    Init method to initialize the UICollectionViewCell with a number label
    
    :param: frame size of the cell
    
    :returns: UICollectionViewCell object
    */
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        numberLabel = UILabel()
        numberLabel.textColor = normalFontColor
        numberLabel.font = UIFont(name: "\(selectedFont)-Medium", size: 30)
        self.contentView.addSubview(numberLabel)
        
        setUpAutoLayoutConstraints()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
    Method to increase number size and animate with a popping effect
    */
    func setAsHighlightedCell() {
        
        self.numberLabel.textColor = highlightedFontColor
        self.numberLabel.font = UIFont(name: "\(selectedFont)-Bold", size: 65)
        self.numberLabel.transform = CGAffineTransformScale(self.numberLabel.transform, 0.5, 0.5)
        UIView.animateWithDuration(0.3, animations: {
            self.numberLabel.transform = CGAffineTransformMakeScale(1.0,1.0)
            
        })
        
    }
    
    /**
    Returns cells back to their original state and smaller size.
    */
    func setAsNormalCell() {
        
        self.numberLabel.textColor = normalFontColor
        self.numberLabel.font = UIFont(name: "\(selectedFont)-Medium", size: 30)
        self.numberLabel.transform = CGAffineTransformScale(self.numberLabel.transform, 2.0, 2.0)
        UIView.animateWithDuration(0.1, animations: {
            self.numberLabel.transform = CGAffineTransformMakeScale(1.0,1.0)
            
        })
        
    }
    
    func setUpAutoLayoutConstraints() {
        
        self.numberLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        self.addConstraint(NSLayoutConstraint(
            item:self.numberLabel, attribute:.CenterX,
            relatedBy:.Equal, toItem:self,
            attribute:.CenterX, multiplier:1, constant:0))
        self.addConstraint(NSLayoutConstraint(
            item:self.numberLabel, attribute:.CenterY,
            relatedBy:.Equal, toItem:self,
            attribute:.CenterY, multiplier:1, constant:0))
    }
    
}


/**
Custom collectionViewFlowLayout in order to have paging on the centered cell
*/
class UICollectionViewFlowLayoutCenterItem: UICollectionViewFlowLayout {
    
    /**
    Init method that sets default properties for collectionViewlayout
    
    :param: viewWidth width of screen to base paddings off of.
    
    :returns: UICollectionViewFlowLayout object
    */
    init(viewWidth: CGFloat) {
        super.init()
        
        let inset = viewWidth/2 - self.itemSize.width/2
        self.sectionInset = UIEdgeInsetsMake(0, inset, 0, inset)
        self.scrollDirection = UICollectionViewScrollDirection.Horizontal
        
        //Ensure that there is only one row
        self.minimumInteritemSpacing = CGFloat(UINT16_MAX)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Obj-C version taken from: https://gist.github.com/mmick66/9812223
    // Method ensures a cell is centered when scrolling has ended
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        let width = self.collectionView!.bounds.size.width
        let proposedContentOffsetCenterX = proposedContentOffset.x + width * CGFloat(0.5)
        let proposedRect = self.layoutAttributesForElementsInRect(self.collectionView!.bounds) as! [UICollectionViewLayoutAttributes]
        
        var candidateAttributes: UICollectionViewLayoutAttributes?
        for attributes in proposedRect {
            
            // this ignores header and footer views
            if attributes.representedElementCategory != UICollectionElementCategory.Cell {
                continue
            }
            
            // set initial value first time through loop
            if (candidateAttributes == nil) {
                candidateAttributes = attributes
                continue
            }
            
            // if placement is desired, update candidateAttributes
            if (fabsf(Float(attributes.center.x) - Float(proposedContentOffsetCenterX)) < fabsf(Float(candidateAttributes!.center.x) - Float(proposedContentOffsetCenterX))) {
                candidateAttributes = attributes
            }
            
        }
    
        return CGPointMake(candidateAttributes!.center.x - width * CGFloat(0.5), proposedContentOffset.y)
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        var oldBounds = self.collectionView!.bounds
        if CGRectGetWidth(oldBounds) != CGRectGetWidth(newBounds) {
            return true
        }
        return false
    }
}