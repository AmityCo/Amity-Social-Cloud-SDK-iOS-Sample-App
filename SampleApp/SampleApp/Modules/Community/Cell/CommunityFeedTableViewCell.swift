//
//  CommunityFeedTableViewCell.swift
//  SampleApp
//
//  Created by Sarawoot Khunsri on 1/7/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import UIKit


class CommunityFeedTableViewCell: UITableViewCell {
    
    @IBOutlet private var postIdLabel: UILabel!
    @IBOutlet private var postUserLabel: UILabel!
    @IBOutlet private var postDataType: UILabel!
    @IBOutlet private var postTextLabel: UILabel!
    @IBOutlet private var postIsDeletedLabel: UILabel!
    @IBOutlet private var postFeedTypeLabel: UILabel!
    @IBOutlet private var postCreatedData: UILabel!
    private var post: CommunityPostModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        postIdLabel.text = "postId: "
        postUserLabel.text = "userDisplayName: "
        postDataType.text = "postDatatype: "
        postTextLabel.text = "postText: "
        postIsDeletedLabel.text = "isDeleted: "
        postFeedTypeLabel.text = "feedType: "
        postCreatedData.text = "createdAt: "

    }
    
    func display(post: CommunityPostModel) {
        postIdLabel.text = "postId: \(post.postId)"
        postUserLabel.text = "userDisplayName: \(post.postedUserDisplayName ?? "-")"
        postDataType.text = "postDatatype: \(post.postDataType)"
        postTextLabel.text = "postText: \(post.text ?? "-")"
        postIsDeletedLabel.text = "isDeleted: \(post.isDeleted)"
        postFeedTypeLabel.text = "feedType: \(getValueForFeedType(feedType: post.feedType))"
        postCreatedData.text = "createdAt: \(post.createdAt)"
    }
    
    private func getValueForFeedType(feedType: AmityFeedType) -> String {
        switch feedType {
        case .published:
            return "published"
        case .reviewing:
            return "reviewing"
        case .declined:
            return "declined"
        @unknown default:
            return "unknown type"
        }
    }
    
}
