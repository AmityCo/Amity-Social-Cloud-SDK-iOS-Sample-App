//
//  FeedPostPollAnswerTableViewCell.swift
//  SampleApp
//
//  Created by Sarawoot Khunsri on 17/8/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import UIKit

class FeedPostPollAnswerTableViewCell: UITableViewCell {

    var answersModel: PollFeedModel.PollFeedAnswerModel?
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        contentView.backgroundColor = .white
    }
    
    func display(model: PollFeedModel.PollFeedAnswerModel) {
        titleLabel.text = "\(model.text) | isVoted: \(model.isVotedByUser) | count: \(model.voteCount)"
        if model.isVotedByUser {
            print(" ")
            contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        } else {
            contentView.backgroundColor = model.isSelected ? UIColor.systemBlue.withAlphaComponent(0.3) : .white
        }
    }

}
