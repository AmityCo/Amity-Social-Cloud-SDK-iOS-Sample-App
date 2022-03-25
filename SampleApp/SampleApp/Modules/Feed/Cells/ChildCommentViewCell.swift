//
//  ChildCommentViewCell.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 2/2/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import UIKit

class ChildCommentViewCell: FeedTableViewCell {
    
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var moreButtonAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarView.layer.cornerRadius = avatarView.frame.height / 2
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .lightGray
        avatarView.image = UIImage(named: "feed_profile")
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        avatarView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
    }
    
    func configure(withComment comment: UserPostCommentModel) {
        titleLabel.text = comment.displayName
        if let metadata = comment.metadata, let mentionees = comment.mentionees {
            subtitleLabel.attributedText = AmityMentionManager.getAttributedString(text: comment.text, withMetadata: metadata, mentionees: mentionees)
        } else {
            subtitleLabel.text = comment.text
        }
        avatarView.image = nil
    }
    
    @IBAction func handleMoreButton(_ sender: Any) {
        moreButtonAction?()
    }
}
