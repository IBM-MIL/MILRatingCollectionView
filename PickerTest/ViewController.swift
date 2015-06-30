//
//  ViewController.swift
//  PickerTest
//
//  Created by Taylor Franklin on 1/7/15.
//  Copyright (c) 2015 MIL. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var milRatingCollectionView: MILRatingCollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        milRatingCollectionView.circularView.backgroundColor = UIColor(red: 0.0/255.0, green: 178.0/255.0, blue: 239.0/255.0, alpha: 1.0)
        milRatingCollectionView.numberRange = NSMakeRange(1, 11) // Default range is 0 to 10, only change if necessary
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Set the starting position for the collectionView before view is visible
        self.milRatingCollectionView.scrollToItemAtIndexPath(milRatingCollectionView.selectedIndexPath!, atScrollPosition: .CenteredHorizontally, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

