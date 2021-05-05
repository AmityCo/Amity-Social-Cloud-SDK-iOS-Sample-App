//
//  FeedPostCommentsCell.swift
//  SampleApp
//
//  Created by Hamlet on 26.03.21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import UIKit

class FeedPostCommentsCell: FeedTableViewCell {

    @IBOutlet weak private var firstCommentLabel: UILabel!
    @IBOutlet weak private var secondCommentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setData(model: PostCommentModel) {
        firstCommentLabel.isHidden = model.firstComment == nil
        secondCommentLabel.isHidden = model.secondComment == nil
        firstCommentLabel.text = model.firstComment
        secondCommentLabel.text = model.secondComment
    }
}
