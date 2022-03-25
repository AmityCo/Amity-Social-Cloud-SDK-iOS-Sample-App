//
//  RealTimeEventHeaderCell.swift
//  SampleApp
//
//  Created by Nishan Niraula on 11/24/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import UIKit

class RealTimeEventHeaderCell: UITableViewCell {
    
    @IBOutlet weak var modelDetailLabel: UILabel!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var unsubscribeButton: UIButton!
    
    var subscribeAction: (() -> Void)?
    var unsubscribeAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        subscribeButton.layer.cornerRadius = 6
        subscribeButton.layer.masksToBounds = true
        unsubscribeButton.layer.cornerRadius = 6
        unsubscribeButton.layer.masksToBounds = true
        
        modelDetailLabel.font = .systemFont(ofSize: 15)
        background.backgroundColor = UIColor.systemGroupedBackground
    }
    
    @IBAction func onSubscribeEventButtonTap(_ sender: Any) {
        subscribeAction?()
    }
    
    @IBAction func onUnsubscribeEventButtonTap(_ sender: Any) {
        unsubscribeAction?()
    }
    
    func hideActionButton() {
        subscribeButton.isEnabled = false
        unsubscribeButton.isEnabled = false

        subscribeButton.isHidden = true
        unsubscribeButton.isHidden = true
    }
    
    func showActionButton() {
        subscribeButton.isEnabled = true
        unsubscribeButton.isEnabled = true

        subscribeButton.isHidden = false
        unsubscribeButton.isHidden = false
    }
}
