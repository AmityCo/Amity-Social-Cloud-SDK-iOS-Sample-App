//
//  FeedPostHeaderCell.swift
//  SampleApp
//
//  Created by Nishan Niraula on 4/27/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit

class FeedPostHeaderCell: FeedTableViewCell {

    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var flagInfo: UILabel!
    
    var moreButtonAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        avatarView.layer.cornerRadius = avatarView.frame.height / 2
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .lightGray
        avatarView.image = UIImage(named: "feed_profile")
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
        
        actionButton.addTarget(self, action: #selector(onMoreButtonTap), for: .touchUpInside)
    }

    @objc func onMoreButtonTap() {
        moreButtonAction?()
    }
    
    func configure(title: String, date: String, isDeleted: Bool) {
        if isDeleted {
            titleLabel.text = "\(title)'s post [Deleted]"
        } else {
            titleLabel.text = "\(title) has shared this post."
        }
        subtitleLabel.text = date
    }
}
