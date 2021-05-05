//
//  CommentTableViewCell.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/12/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit

final class CommentTableViewCell: UITableViewCell, AmityChatTableViewCell {
    typealias AmityComment = AmityMessage
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var timeStampLabel: UILabel!
    @IBOutlet weak var commentDeliveryStatus: UIImageView!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var replyToLabel: UILabel!
    @IBOutlet weak var commentHeaderView: UIView!
    @IBOutlet weak var verticalStackView: UIStackView!

    private var commentId: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        verticalStackView.setCustomSpacing(0, after: commentHeaderView)
    }

    func display(_ comment: AmityComment, client: AmityClient) {
        commentId = comment.messageId
        let createdDateText = DateFormatter.localizedString(from: comment.createdAtDate,
                                                            dateStyle: .none,
                                                            timeStyle: .short)
        timeStampLabel.text = createdDateText
        commentDeliveryStatus.image = symbol(for: comment.syncState)
        commentDeliveryStatus.tintColor = color(for: comment.syncState)

        let messageText: String = comment.data?["text"] as? String ?? ""
        commentLabel.text = messageText
        displayNameLabel.text = comment.user?.displayName ?? "@\(comment.userId)"

        configureReplyLabel(for: comment, client: client)
    }

    private func configureReplyLabel(for comment: AmityComment, client: AmityClient) {
        let replyLabelText: String

        if comment.childrenNumber > 0 {
            replyLabelText = "View \(comment.childrenNumber) Replies"
        } else {
            replyLabelText = "Reply"
        }

        replyToLabel.text = replyLabelText
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
}
