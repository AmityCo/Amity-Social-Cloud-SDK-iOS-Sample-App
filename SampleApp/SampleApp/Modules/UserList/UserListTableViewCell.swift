//
//  UserListTableViewCell.swift
//  SampleApp
//
//  Created by Nishan Niraula on 5/11/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit

protocol UserListTableViewCellDelegate: AnyObject {
    func cellOptionDidTap(_ cell: UserListTableViewCell)
}

class UserListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var avatarLabel: UILabel!
    
    weak var delegate: UserListTableViewCellDelegate?
    
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
    
    @IBAction func optionTapped(_ sender: Any) {
        delegate?.cellOptionDidTap(self)
    }
    
}
