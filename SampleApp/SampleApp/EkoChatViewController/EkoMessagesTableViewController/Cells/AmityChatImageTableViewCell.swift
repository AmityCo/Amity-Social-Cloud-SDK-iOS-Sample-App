//
//  AmityChatImageTableViewCell.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/16/18.
//  Copyright © 2018 David Zhang. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityChatImageTableViewCell: UITableViewCell, AmityChatTableViewCell {
    @IBOutlet weak var myImageView: UIImageView!
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
    
    var messageRepo: AmityMessageRepository!
    
    var fileRepo = AmityFileRepository(client: AmityManager.shared.client!)

    private func set(image: UIImage) {
        myImageView.image = image
    }

    func display(_ message: AmityMessage, client: AmityClient) {
        messageId = message.messageId

        if message.isDeleted {
            timeLabel.text = "Message Deleted"
            displayNameLabel.text = "Message Deleted"
        } else {
            let flagCount = message.flagCount
            
            displayNameLabel.text = message.user?.displayName ?? "" + " F: (\(flagCount)"
            messageStatusImageView.image = symbol(for: message.syncState)
            timeLabel.text = DateFormatter.localizedString(from: message.createdAtDate, dateStyle: .none, timeStyle: .short)
            if (messageRepo == nil || messageRepo.client != client) {
                messageRepo = AmityMessageRepository(client: client)
            }

            guard !message.isDeleted else {
                self.aspectRatioConstraint = self.myImageView.widthAnchor.constraint(equalTo: self.myImageView.heightAnchor,
                multiplier: 1)
                self.myImageView.image = UIImage(named:"picture")
                self.myImageView.tintColor = UIColor.gray
                return
            }
                        
            if let _ = message.fileId, message.messageType == .image {
                
                if message.syncState == .synced {
                    // For synced message, the local file path previously returned will be replaced by the actual web url of the image.
                    // You can fetch the image from server and cache it with messageId or fileId as the key.
                    // Or you can still use local image here if its still available.
                    guard let imageInfo = message.getImageInfo() else { return }
                    ImageMessageHandler.shared.fetchImage(fileURL: imageInfo.fileURL) { [weak self] (image) in
                        self?.updateImage(image: image)
                    }
                } else {
                    guard let imageInfo = message.getImageInfo(), let imageURL = URL(string: imageInfo.fileURL) else { return }
                    if let image = UIImage(contentsOfFile: imageURL.path) {
                        Log.add(info: "[IMAGE] Success loading image in syncing state")
                        self.updateImage(image: image)
                    } else {
                        Log.add(info: "[IMAGE] Error loading image in syncing state")
                    }
                    
                    
                }
            }
        }
    }
    
    func updateImage(image: UIImage?) {
        guard let image = image else { return }
        
        let aspect = image.size.width / image.size.height
        self.aspectRatioConstraint = self.myImageView.widthAnchor.constraint(equalTo: self.myImageView.heightAnchor, multiplier: aspect)
        self.myImageView.image = image
    }

    private func symbol(for status: AmitySyncState) -> UIImage {
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
