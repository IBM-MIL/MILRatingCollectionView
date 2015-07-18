/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit

class ViewController: UIViewController {
    
    var _height: CGFloat { return self.view.frame.height }
    
    var mil: MILRatingCollectionView? {
        
        var returnMIL: MILRatingCollectionView?
        
        for view in self.view.subviews as! [UIView] {
            
            if view.tag == 999 {
                returnMIL = view as? MILRatingCollectionView
            }
            
        }
        
        return returnMIL
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        mil?.constants.normalFontColor = UIColor.blackColor()
        
    }
    
    @IBAction func scrollTo9() { mil?.constants.selectedIndex = 9 }
    @IBAction func scrollTo1() { mil?.constants.selectedIndex = 1 }
    
    var toggledYellow = false
    var neverTouchedCircle = true
    var saveColor: UIColor!
    @IBAction func toggleCircleBackground() {
        
        if mil != nil {
            
            if neverTouchedCircle {
                saveColor = mil!.constants.circleBackgroundColor
                neverTouchedCircle = false
            }
            
            if toggledYellow {
                mil!.constants.circleBackgroundColor = saveColor
            } else {
                mil!.constants.circleBackgroundColor = UIColor.yellowColor()
            }
            
            toggledYellow = !toggledYellow
            
            
        }
        
    }
    
    var numVisibleNeverTouched = true
    var numVisibleToggled = false
    var oldNumVisible: Int!
    @IBAction func toggleNumVisible() {
        
        if mil != nil {
            
            if numVisibleNeverTouched {
                numVisibleNeverTouched = false
                oldNumVisible = mil!.constants.numCellsVisible
            }
            
            if numVisibleToggled {
                mil!.constants.numCellsVisible = oldNumVisible
            } else {
                mil!.constants.numCellsVisible = 3
            }
            
            numVisibleToggled = !numVisibleToggled
            
        }
        
    }
    
    var backgroundToggled = false
    var backgroundNeverTouched = true
    var oldBackgroundColor: UIColor!
    @IBAction func toggleBackground() {
        
        if mil != nil {
            
            if backgroundNeverTouched {
                backgroundNeverTouched = false
                oldBackgroundColor = mil!.constants.backgroundColor
            }
            
            if backgroundToggled {
                mil!.constants.backgroundColor = oldBackgroundColor
            } else {
                mil!.constants.backgroundColor = UIColor.redColor()
            }
            
            backgroundToggled = !backgroundToggled
            
        }
        
    }
    
}
