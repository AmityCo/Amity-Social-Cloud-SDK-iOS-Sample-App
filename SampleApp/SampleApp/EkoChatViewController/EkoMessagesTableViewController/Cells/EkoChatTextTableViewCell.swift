//
//  EkoChatTextTableViewCell.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/25/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import EkoChat

protocol EkoChatTextTableViewCellDelegate: AnyObject {
    func chatTextDidReact(_ cell: EkoChatTextTableViewCell, withReaction reaction: String)
}

@objc final class EkoChatTextTableViewCell: UITableViewCell, EkoChatTableViewCell {
    @IBOutlet private weak var bubbleImageView: UIImageView!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var displayNameLabel: UILabel!
    @IBOutlet private weak var metadataLabel: UILabel!
    @IBOutlet private weak var messageStatusImageView: UIImageView!
    @IBOutlet private weak var likeButton: UIButton!
    
    weak var delegate: EkoChatTextTableViewCellDelegate?
    
    // MARK: Lifecyle
        
    override func awakeFromNib() {
        super.awakeFromNib()
        likeButton.backgroundColor = .white
        likeButton.layer.cornerRadius = 2
        likeButton.layer.borderWidth = 1
        likeButton.layer.borderColor = UIColor.black.cgColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        metadataLabel.text = ""
        messageStatusImageView.image = nil
        likeButton.backgroundColor = .white
        likeButton.layer.cornerRadius = 2
        likeButton.layer.borderWidth = 1
        likeButton.layer.borderColor = UIColor.black.cgColor
    }
    
    @IBAction func handleLikeButton(_ sender: Any) {
        delegate?.chatTextDidReact(self, withReaction: "Like")
    }
    
    // MARK: EkoChatTableViewCell

    func display(_ message: EkoMessage, client: EkoClient) {
        setState(for: message)
        setMetadata(for: message)
        setText(for: message)
        setDisplayName(for: message)
        setLikeButton(for: message)
    }
        
    private func setLikeButton(for message: EkoMessage) {
        if let reactions = message.reactions as? [String: Int] {
            let containLike = reactions.contains { (key, _) -> Bool in
                return key == "Like"
            }
            guard containLike else {
                likeButton.backgroundColor = .white
                likeButton.setTitleColor(.systemGreen, for: .normal)
                return
            }
            if message.myReactions.contains("Like") {
                likeButton.backgroundColor = .red
                likeButton.setTitleColor(.white, for: .normal)
            } else {
                likeButton.backgroundColor = .white
                likeButton.setTitleColor(.systemGreen, for: .normal)
            }
        } else {
            likeButton.backgroundColor = .white
            likeButton.setTitleColor(.systemGreen, for: .normal)
        }
    }
    
    private func setState(for message: EkoMessage) {
        setState(message.syncState)
    }

    private func setState(_ state: EkoSyncState) {
        messageStatusImageView.image = symbol(for: state)
        messageStatusImageView.tintColor = color(for: state)
    }

    /// Returns a proper image for the given `EkoSyncState` instance.
    private func symbol(for state: EkoSyncState) -> UIImage? {
        switch state {
        case .default, .synced, .syncing:
            return UIImage(named: "check")
        case .error:
            return UIImage(named: "error")
        @unknown default:
            return UIImage(named: "error")
        }
    }

    /// Returns a proper color for the given `EkoSyncState` instance.
    private func color(for state: EkoSyncState) -> UIColor? {
        switch state {
        case .default, .synced:
            return UIColor(named: "EkoGreen")
        case .syncing:
            return UIColor(named: "EkoGray")
        case .error:
            return UIColor(named: "EkoRed")
        @unknown default:
            return UIColor(named: "EkoRed")
        }
    }

    private func setText(for message: EkoMessage) {
        if message.isDeleted {
            setText("Message deleted")
        } else if message.messageType == .text {
            setText(message.data?["text"] as? String)
        } else if message.messageType == .custom {
            let string = "This is custom file message type:\n\(message.data?.description ?? "")"
            setText(string)
        }
    }

    private func setText(_ text: String?) {
        messageLabel.text = text ?? ""
    }

    private func setDisplayName(for message: EkoMessage) {
        setDisplayName(message.user?.displayName)
    }

    private func setDisplayName(_ name: String?) {
        displayNameLabel.text = name
    }

    private func setMetadata(for message: EkoMessage) {
        let messageCreateDate: NSAttributedString? = createDate(for: message)
        let messageTags: NSAttributedString? = tags(for: message)
        let childMessages: NSAttributedString? = self.childMessages(for: message)
        let hasParent: NSAttributedString? = parent(for: message)

        let mutableAttributedString = NSMutableAttributedString()

        let optionalAttributedStrings: [NSAttributedString?] = [
            hasParent,
            childMessages,
            messageTags,
            messageCreateDate
        ]

        let attributedStrings: [NSAttributedString] = optionalAttributedStrings.compactMap { $0 }
        for attributedString in attributedStrings {
            mutableAttributedString.append(NSAttributedString(string: " "))
            mutableAttributedString.append(attributedString)
        }
        metadataLabel.attributedText = mutableAttributedString
    }

    private func createDate(for message: EkoMessage) -> NSAttributedString {
        let createDateString: String = DateFormatter.localizedString(from: message.createdAtDate,
                                                                     dateStyle: .none,
                                                                     timeStyle: .short)
        return NSAttributedString(string: createDateString)
    }

    private func tags(for message: EkoMessage) -> NSAttributedString? {
        if let messageTags = message.tags as? [String],
            !messageTags.isEmpty {
            return attributedString(for: messageTags)
        }
        return nil
    }

    private func attributedString(for tags: [String]) -> NSAttributedString {
        assert(!tags.isEmpty)
        let colors: [UIColor] = ["PastelRed", "PastelOrange", "PastelYellow",
                                 "PastelGreen", "PastelBlue", "PastelPurple",
                                 "NeonPink", "NeonRed", "NeonGreen", "NeonAzure"].compactMap(UIColor.init)

        let mutableAttributedString = NSMutableAttributedString()
        for index in 0..<tags.count {
            let index = index % colors.count
            let attributedTagString = NSAttributedString(string: " \(tags[index]) ",
                attributes: [.backgroundColor: colors[index],
                             .foregroundColor: .white])
            mutableAttributedString.append(attributedTagString)
            mutableAttributedString.append(NSAttributedString(string: " "))
        }
        return mutableAttributedString
    }

    private func childMessages(for message: EkoMessage) -> NSAttributedString? {
        if message.childrenNumber > 0 {
            let attributedTagString = NSAttributedString(string: " childs: \(message.childrenNumber) ",
                attributes: [.backgroundColor: UIColor.black,
                             .foregroundColor: .white])
            return attributedTagString
        }
        return nil
    }

    private func parent(for message: EkoMessage) -> NSAttributedString? {
        if message.parentId != nil {
            return NSAttributedString(string: "🧒🏻")
        }
        return nil
    }
}
