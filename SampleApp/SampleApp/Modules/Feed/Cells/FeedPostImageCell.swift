//
//  FeedPostImageCell.swift
//  SampleApp
//
//  Created by Nishan Niraula on 7/10/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit

protocol FeedPostImageCellDelegate: AnyObject {
    func feedPostImageCellDidTapImage(_ cell: FeedPostImageCell, videoFeedModel: VideoFeedModel)
}

class FeedPostImageCell: UITableViewCell {
    
    weak var delegate: FeedPostImageCellDelegate?
    
    var videoFeedModel: VideoFeedModel?
    
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        imageView1.addGestureRecognizer(tapGesture)
        imageView1.isUserInteractionEnabled = true
        imageView1.contentMode = .scaleAspectFill
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView1.image = nil
        videoFeedModel = nil
    }
    
    @objc private func didTapImage() {
        if let videoFeedModel = videoFeedModel {
            delegate?.feedPostImageCellDidTapImage(self, videoFeedModel: videoFeedModel)
        }
    }
    
    
}
