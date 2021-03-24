//
//  ChildCommentViewCell.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 2/2/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import Foundation

class ChildCommentViewCell: FeedTableViewCell {
    
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
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
        titleLabel.text = displayName
        subtitleLabel.text = comment
        avatarView.image = displayImage
    }
    
}
