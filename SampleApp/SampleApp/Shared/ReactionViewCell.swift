//
//  ReactionViewCell.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 12/24/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit

final class ReactionViewCell: UITableViewCell {
    
    @IBOutlet private weak var reactionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    func setTitle(reaction: String, user: String) {
        reactionLabel.text = "\(reaction) by \(user)"
    }
    
}
