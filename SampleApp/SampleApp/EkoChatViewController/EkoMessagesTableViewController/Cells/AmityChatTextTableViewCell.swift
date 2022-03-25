//
//  AmityChatTextTableViewCell.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/25/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityChatTextTableViewCellDelegate: AnyObject {
    func chatTextDidReact(_ cell: AmityChatTextTableViewCell, withReaction reaction: String)
    func chatTextDidTapOnMention(_ cell: AmityChatTextTableViewCell, withType type: AmityMessageMentionType, userId: String?)
}

@objc final class AmityChatTextTableViewCell: UITableViewCell, AmityChatTableViewCell {
    
    @IBOutlet private weak var bubbleImageView: UIImageView!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var displayNameLabel: UILabel!
    @IBOutlet private weak var metadataLabel: UILabel!
    @IBOutlet private weak var messageStatusImageView: UIImageView!
    @IBOutlet private weak var likeButton: UIButton!
    
    weak var delegate: AmityChatTextTableViewCellDelegate?
    private var message: AmityMessage?
    private var mentions: [AmityMention] = [AmityMention]()
    
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
        messageLabel.attributedText = nil
        messageLabel.text = ""
        mentions = []
    }
    
    @IBAction func handleLikeButton(_ sender: Any) {
        delegate?.chatTextDidReact(self, withReaction: "Like")
    }
    
    // MARK: AmityChatTableViewCell

    func display(_ message: AmityMessage, client: AmityClient) {
        setState(for: message)
        setMetadata(for: message)
        setText(for: message)
        setDisplayName(for: message)
        setLikeButton(for: message)
    }
        
    private func setLikeButton(for message: AmityMessage) {
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
    
    private func setState(for message: AmityMessage) {
        setState(message.syncState)
    }

    private func setState(_ state: AmitySyncState) {
        messageStatusImageView.image = symbol(for: state)
        messageStatusImageView.tintColor = color(for: state)
    }

    /// Returns a proper image for the given `AmitySyncState` instance.
    private func symbol(for state: AmitySyncState) -> UIImage? {
        switch state {
        case .default, .synced, .syncing:
            return UIImage(named: "check")
        case .error:
            return UIImage(named: "error")
        @unknown default:
            return UIImage(named: "error")
        }
    }

    /// Returns a proper color for the given `AmitySyncState` instance.
    private func color(for state: AmitySyncState) -> UIColor? {
        switch state {
        case .default, .synced:
            return UIColor(named: "AmityGreen")
        case .syncing:
            return UIColor(named: "AmityGray")
        case .error:
            return UIColor(named: "AmityRed")
        @unknown default:
            return UIColor(named: "AmityRed")
        }
    }
    
    private func setText(for message: AmityMessage) {
        if let metadata = message.metadata {
            mentions = AmityMentionMapper.mentions(fromMetadata: metadata)
        }
        if message.isDeleted {
            setText("Message deleted")
        } else if message.messageType == .text {
            if !mentions.isEmpty {
                setMentionText(for: message)
            } else {
                setText(message.data?["text"] as? String)
            }
        } else if message.messageType == .custom {
            let string = message.data?.description
            setText(string)
        }
        
    }

    private func setText(_ text: String?) {
        messageLabel.text = text ?? ""
        
    }

    private func setMentionText(for message: AmityMessage) {
        guard let text = message.data?["text"] as? String, !text.isEmpty else { return }
        self.message = message
        let attributedString = NSMutableAttributedString.init(string: text)
        
        for mention in mentions {
            let mentioneesUser = message.mentionees?.filter({ mentionee in
                mentionee.type == .user
            })
            
            if let mentioneesUserArray = mentioneesUser, !mentioneesUserArray.isEmpty, let users = mentioneesUserArray.first?.users  {
                let user = users.filter { $0.userId == mention.userId && $0.isGlobalBan }

                if !user.isEmpty { continue }
            }
            
            let range = NSRange(location: mention.index, length: mention.length + 1)
            if range.location != NSNotFound && range.location + range.length <= text.count {
                attributedString.addAttribute(.foregroundColor, value: UIColor.green, range: range)
            }
        }
        
        messageLabel.attributedText = attributedString
        messageLabel.isUserInteractionEnabled = true
        messageLabel.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(tappedOnLabel(_:))))
    }
    
    private func setDisplayName(for message: AmityMessage) {
        let messageInfo = message.user?.displayName ?? ""
        let flagCount = message.flagCount
        
        displayNameLabel.text = messageInfo + "- F:(\(flagCount))"
    }

    private func setMetadata(for message: AmityMessage) {
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

    private func createDate(for message: AmityMessage) -> NSAttributedString {
        let createDateString: String = DateFormatter.localizedString(from: message.createdAtDate,
                                                                     dateStyle: .none,
                                                                     timeStyle: .short)
        return NSAttributedString(string: createDateString)
    }

    private func tags(for message: AmityMessage) -> NSAttributedString? {
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

    private func childMessages(for message: AmityMessage) -> NSAttributedString? {
        if message.childrenNumber > 0 {
            let attributedTagString = NSAttributedString(string: " childs: \(message.childrenNumber) ",
                attributes: [.backgroundColor: UIColor.black,
                             .foregroundColor: .white])
            return attributedTagString
        }
        return nil
    }

    private func parent(for message: AmityMessage) -> NSAttributedString? {
        if message.parentId != nil {
            return NSAttributedString(string: "🧒🏻")
        }
        return nil
    }
    
    @objc func tappedOnLabel(_ gesture: UITapGestureRecognizer) {
        guard let _ = self.messageLabel.text else { return }
        
        for mention in mentions {
            if mention.type == .channel {
                continue
            }
            
            let range = NSRange(location: mention.index, length: mention.length)
            if gesture.didTapAttributedTextInLabel(label: messageLabel, inRange: range) {
                delegate?.chatTextDidTapOnMention(self, withType: mention.type, userId: mention.userId)
                return
            }
        }
    }
}

extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
            // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        
        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
            
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
            
        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                         y: locationOfTouchInLabel.y - textContainerOffset.y)
        var indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        indexOfCharacter = indexOfCharacter + 4
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}
