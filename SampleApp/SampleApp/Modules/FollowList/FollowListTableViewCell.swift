//
//  FollowListTableViewCell.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 14/6/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import UIKit

protocol FollowListTableViewCellDelegate: AnyObject {
    func actionButtonDidTap(_ cell: FollowListTableViewCell, action: FollowListActionType)
}

enum FollowListActionType {
    case accept
    case decline
    case unfollow
    case cancel
    case remove
}

class FollowListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var avatarLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var unfollowButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    
    weak var delegate: FollowListTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        userImageView.layer.masksToBounds = true
        userImageView.backgroundColor = .lightGray
        userImageView.image = UIImage(named: "feed_profile")
        userImageView.layer.borderWidth = 2
        userImageView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
        
        userNameLabel.textColor = .darkText
        userIdLabel.textColor = .darkGray
    }
    
    func configure(with actions: [FollowListActionType]) {
        acceptButton.isHidden = !actions.contains(.accept)
        declineButton.isHidden = !actions.contains(.decline)
        unfollowButton.isHidden = !actions.contains(.unfollow)
        cancelButton.isHidden = !actions.contains(.cancel)
        removeButton.isHidden = !actions.contains(.remove)
    }
    
    @IBAction func acceptTapped(_ sender: Any) {
        delegate?.actionButtonDidTap(self, action: .accept)
    }
    
    @IBAction func declineTapped(_ sender: Any) {
        delegate?.actionButtonDidTap(self, action: .decline)
    }
    
    @IBAction func unfollowTapped(_ sender: Any) {
        delegate?.actionButtonDidTap(self, action: .unfollow)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        delegate?.actionButtonDidTap(self, action: .cancel)
    }
    
    @IBAction func removeTapped(_ sender: Any) {
        delegate?.actionButtonDidTap(self, action: .remove)
    }
    
}
