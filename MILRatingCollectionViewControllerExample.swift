/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit

class ____MILRatingCollectionViewControllerExample: UIViewController {
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let currFrame = self.view.frame
        let bobsFrame = CGRect(x: 0.0, y: 40.0, width: currFrame.width, height: currFrame.height/5)
        
        let bob = MILUI.RatingCollectionView(frame: bobsFrame)
        
        var bobConstants = MILUI.RatingCollectionView.Constants()
            bobConstants.fontAnimated = true
            bobConstants.backgroundColor = UIColor.blueColor()
            bobConstants.circleBackgroundColor = UIColor.cyanColor()
            bobConstants.numberRange = NSMakeRange(4, 21)
        
        bob.constants = bobConstants
        
        self.view.addSubview(bob)
        
    }

    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }

}

