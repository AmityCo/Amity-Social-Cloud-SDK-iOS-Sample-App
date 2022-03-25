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
        
        if let firstComment = model.firstComment, let text = firstComment.data?["text"] as? String {
            if let mentionees = firstComment.mentionees, let metadata = firstComment.metadata {
                firstCommentLabel.attributedText = AmityMentionManager.getAttributedString(text: text, withMetadata: metadata, mentionees: mentionees)
            } else {
                firstCommentLabel.text = text
            }
        }
        
        if let secondComment = model.secondComment, let text = secondComment.data?["text"] as? String {
            if let mentionees = secondComment.mentionees, let metadata = secondComment.metadata {
                secondCommentLabel.attributedText = AmityMentionManager.getAttributedString(text: text, withMetadata: metadata, mentionees: mentionees)
            } else {
                secondCommentLabel.text = text
            }
        }
    }
}
