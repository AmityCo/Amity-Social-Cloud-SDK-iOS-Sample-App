//
//  NotificationModuleTableViewCell.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 12/3/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import Foundation

protocol NotificationModuleTableViewCellDelegate: class {
    func cell(_ cell: NotificationModuleTableViewCell, valueDidChange isEnabled: Bool)
    func cellRoleButtonDidTap(_ cell: NotificationModuleTableViewCell)
}

class NotificationModuleTableViewCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var toggleSwitch: UISwitch!
    @IBOutlet weak var roleButton: UIButton!
    
    private var isEnabled: Bool {
        return toggleSwitch.isOn
    }
    
    private(set) var acceptOnlyModerator: Bool = false {
        didSet {
            let title = acceptOnlyModerator ? "Only Moderator" : "Everyone"
            roleButton.setTitle(title, for: .normal)
        }
    }
    
    weak var delegate: NotificationModuleTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    func configure(title: String, isEnabled: Bool, isModerator: Bool) {
        titleLabel?.text = title
        toggleSwitch?.isOn = isEnabled
        self.acceptOnlyModerator = isModerator
    }
    
    @IBAction func roleButtonTapped(_ sender: Any) {
        acceptOnlyModerator.toggle()
        delegate?.cellRoleButtonDidTap(self)
    }
    
    @IBAction func toggleValueChanged(_ sender: UISwitch) {
        delegate?.cell(self, valueDidChange: sender.isOn)
    }
}
