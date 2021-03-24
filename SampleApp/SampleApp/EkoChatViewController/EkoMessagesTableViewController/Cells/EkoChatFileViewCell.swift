//
//  EkoChatFileViewCell.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 10/11/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import Foundation

final class EkoChatFileViewCell: UITableViewCell, EkoChatTableViewCell {
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myMessageLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var myDisplayNameLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var someoneMessageLabelLeadingingConstraint: NSLayoutConstraint!
    @IBOutlet weak var someoneDisplayNameLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageStatusImageView: UIImageView!
    
    private var messageId: String?
    
    var aspectRatioConstraint: NSLayoutConstraint? {
        didSet {
            if let oldValue = oldValue {
                oldValue.isActive = false
            }
            if let aspectRatioConstraint = aspectRatioConstraint {
                aspectRatioConstraint.isActive = true
            }
        }
    }
    
    private func set(image: UIImage) {
        myImageView.image = image
    }
    
    func display(_ message: EkoMessage, client: EkoClient) {
        messageId = message.messageId
        
        if message.userId == client.currentUserId {
            myMessageLabelTrailingConstraint.isActive = true
            myDisplayNameLabelTrailingConstraint.isActive = true
            someoneMessageLabelLeadingingConstraint.isActive = false
            someoneDisplayNameLabelLeadingConstraint.isActive = false
        } else {
            myMessageLabelTrailingConstraint.isActive = false
            myDisplayNameLabelTrailingConstraint.isActive = false
            someoneMessageLabelLeadingingConstraint.isActive = true
            someoneDisplayNameLabelLeadingConstraint.isActive = true
        }
        self.needsUpdateConstraints()
        self.setNeedsLayout()
        
        if message.isDeleted {
            displayNameLabel.text = "Message deleted"
        } else {
            displayNameLabel.text = message.user?.displayName
            messageStatusImageView.image = symbol(for: message.syncState)
            myImageView.image = UIImage(named:"file")
            timeLabel.text = DateFormatter.localizedString(from: message.createdAtDate, dateStyle: .none, timeStyle: .short)
            
            if !message.isDeleted {
                
                let audioIcon = UIImage(systemName: "waveform")
                let fileIcon = UIImage(systemName: "doc")
                
                self.aspectRatioConstraint = self.myImageView.widthAnchor.constraint(equalTo: self.myImageView.heightAnchor, multiplier: 1)
                self.myImageView.image = message.messageType == .audio ? audioIcon : fileIcon
                self.myImageView.tintColor = UIColor.gray
            }
        }
    }
    
    private func symbol(for status: EkoSyncState) -> UIImage? {
        switch status {
        case .default, .synced: return #imageLiteral(resourceName: "check")
        case .syncing: return UIImage(systemName: "arrow.up")
        case .error: return #imageLiteral(resourceName: "error")
        @unknown default: return UIImage()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        aspectRatioConstraint = nil
        myImageView.image = nil
        timeLabel.text = ""
        messageStatusImageView.image = nil
    }
}

extension EkoMessageType {
    
    var description: String {
        switch self {
        case .audio:
            return "Audio"
        case .image:
            return "Image"
        case .file:
            return "File"
        case .custom:
            return "Custom"
        case .text:
            return "Text"
        @unknown default:
            return "Unknown"
        }
    }
}
