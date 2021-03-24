//
//  FeedPostImageCell.swift
//  SampleApp
//
//  Created by Nishan Niraula on 7/10/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit

class FeedPostImageCell: UITableViewCell {

    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView1.image = nil
    }
}
