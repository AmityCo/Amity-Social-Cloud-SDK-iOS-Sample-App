//
//  ChannelListTableViewCellConfigurator.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/29/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import AmitySDK

final class ChannelListTableViewCellConfigurator {
    
    func configure(_ cell: SampleAppTableViewCell, with channel: AmityChannel) {
        setTitleLabel(for: cell, with: channel)
        setSubtitleLabel(for: cell, with: channel)
        setDetailLabel(for: cell, with: channel)
    }
    
    // MARK: Title
    
    private func setTitleLabel(for cell: SampleAppTableViewCell, with channel: AmityChannel) {
        cell.titleLabel.text = channel.displayName ?? channel.channelId
    }
    
    // MARK: Subtitle
    
    private func setSubtitleLabel(for cell: SampleAppTableViewCell, with channel: AmityChannel) {
        guard let channelTags = channel.tags as? [String] else { return }
        let tagsAttributedString: NSAttributedString = attributedString(for: channelTags)
        let channelEmoji: String = emoji(for: channel.channelType)
        let mutableAttributedString = NSMutableAttributedString(string: "\(channelEmoji) ")
        mutableAttributedString.append(tagsAttributedString)
        cell.subtitleLabel.attributedText = mutableAttributedString
    }
    
    private func attributedString(for tags: [String]) -> NSAttributedString {
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
    
    private func emoji(for channelType: AmityChannelType) -> String {
        return "Type: \(channelType.description)"
    }
    
    // MARK: Detail
    
    private func setDetailLabel(for cell: SampleAppTableViewCell, with channel: AmityChannel) {
        let detailText: String
        if
            channel.currentUserMembership == .member,
            channel.unreadCount != 0 {
            let mentionIndicator = channel.hasMention ? "@" : ""
            detailText = "🆕 \(channel.unreadCount) \(mentionIndicator)"
        } else {
            let memberCount = channel.memberCount
            detailText = channel.currentUserMembership.description + " (\(memberCount))"
        }
        cell.detailLabel.text = detailText
    }
}

extension AmityChannelMembershipType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .banned: return "banned"
        case .member: return "member"
        case .none: return "notMember"
        @unknown default: return "unknown"
        }
    }
}
