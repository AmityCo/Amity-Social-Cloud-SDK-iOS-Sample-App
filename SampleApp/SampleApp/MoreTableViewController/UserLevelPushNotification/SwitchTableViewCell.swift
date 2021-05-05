//
//  SwitchTableViewCell.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 11/3/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import UIKit

protocol SwitchTableViewCellDelegate: class {
    func cell(_ cell: SwitchTableViewCell, valueDidChange isEnabled: Bool)
}

class SwitchTableViewCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var toggleSwitch: UISwitch!
    
    private var isEnabled: Bool {
        return toggleSwitch.isOn
    }
    
    weak var delegate: SwitchTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    func configure(title: String, isEnabled: Bool) {
        titleLabel?.text = title
        toggleSwitch?.isOn = isEnabled
    }
    
    @IBAction func toggleValueChanged(_ sender: UISwitch) {
        delegate?.cell(self, valueDidChange: sender.isOn)
    }
}
