//
//  CommentViewCell.swift
//  SampleApp
//
//  Created by Michael Abadi on 10/06/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit

class CommentViewCell: FeedTableViewCell {

    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var reactionLabel: UILabel!
    
    var replyButtonAction: (() -> Void)?
    var moreButtonAction: (() -> Void)?
    var reactButtonAction: (()->Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarView.layer.cornerRadius = avatarView.frame.height / 2
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .lightGray
        avatarView.image = UIImage(named: "feed_profile")
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
    }
    
    func configure(displayName: String, comment: String, displayImage: UIImage?) {
        titleLabel.text = "\(displayName) commented to this post."
        subtitleLabel.text = comment
        avatarView.image = displayImage
    }
    
    @IBAction func handleReplyButton(_ sender: Any) {
        replyButtonAction?()
    }
    
    @IBAction func handleMoreButton(_ sender: Any) {
        moreButtonAction?()
    }
    
    @IBAction func handleReactionAction(_ sender: Any) {
        reactButtonAction?()
    }
}
