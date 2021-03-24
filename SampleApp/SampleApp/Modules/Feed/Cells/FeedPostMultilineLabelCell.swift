//
//  FeedPostMultilineLabelCell.swift
//  SampleApp
//
//  Created by Nishan Niraula on 4/27/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit

class FeedPostMultilineLabelCell: FeedTableViewCell {

    @IBOutlet weak var feedTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.feedTextLabel.text = "This is the test for multiline texts. This TableView should automatically handle multiple lines of text with autolayout. Even if the length of the text is greater than container, the container should wrap it perfectly. Let's see if it works or not"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
