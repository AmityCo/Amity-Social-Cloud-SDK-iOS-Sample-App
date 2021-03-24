//
//  FeedPostFooterCell.swift
//  SampleApp
//
//  Created by Nishan Niraula on 4/27/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit

/// Cell with Like, Comment action buttons
class FeedPostFooterCell: FeedTableViewCell {
    
    @IBOutlet weak var commentImageView: UIImageView!
    @IBOutlet weak var likeImageView: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var loveButton: UIButton!
    
    var likeButtonAction: (() -> Void)?
    var loveButtonAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        likeButton.addTarget(self, action: #selector(onLikeButtonTap), for: .touchUpInside)
        loveButton.addTarget(self, action: #selector(onLoveButtonTap), for: .touchUpInside)
        
        likeImageView.tintColor = .gray
        commentImageView.tintColor = .gray
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func onLikeButtonTap() {
        likeButtonAction?()
    }
    
    @objc func onLoveButtonTap() {
        loveButtonAction?()
    }
}
