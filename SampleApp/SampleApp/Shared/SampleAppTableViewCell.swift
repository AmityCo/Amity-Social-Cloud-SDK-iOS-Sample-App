//
//  SampleAppTableViewCell.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/11/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit

final class SampleAppTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.text = ""
        subtitleLabel.text = ""
        detailLabel.text = ""
    }
}
