//
//  EkoChatImageTableViewCell.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/16/18.
//  Copyright © 2018 David Zhang. All rights reserved.
//

import UIKit
import EkoChat

final class EkoChatImageTableViewCell: UITableViewCell, EkoChatTableViewCell {
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
    
    var messageRepo: EkoMessageRepository!

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
            timeLabel.text = "Message Deleted"
            displayNameLabel.text = "Message Deleted"
        } else {
            displayNameLabel.text = message.user?.displayName
            messageStatusImageView.image = symbol(for: message.syncState)
            timeLabel.text = DateFormatter.localizedString(from: message.createdAtDate, dateStyle: .none, timeStyle: .short)
            if (messageRepo == nil || messageRepo.client != client) {
                messageRepo = EkoMessageRepository(client: client)
            }

            guard !message.isDeleted else {
                self.aspectRatioConstraint = self.myImageView.widthAnchor.constraint(equalTo: self.myImageView.heightAnchor,
                multiplier: 1)
                self.myImageView.image = UIImage(named:"picture")
                self.myImageView.tintColor = UIColor.gray
                return
            }
                        
            if let _ = message.fileId, message.messageType == .image {
                messageRepo.downloadImage(for: message, size: .medium) { [weak self] (imageData, error) in
                    if let imageData = imageData, let image = UIImage(data: imageData), let imageView = self?.myImageView {
                        
                        let aspect = image.size.width / image.size.height
                        self?.aspectRatioConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: aspect)
                        self?.myImageView.image = image
                    }
                }
            }
        }
    }

    private func symbol(for status: EkoSyncState) -> UIImage {
        switch status {
        case .default, .synced: return #imageLiteral(resourceName: "check")
        case .syncing: return #imageLiteral(resourceName: "check")
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
