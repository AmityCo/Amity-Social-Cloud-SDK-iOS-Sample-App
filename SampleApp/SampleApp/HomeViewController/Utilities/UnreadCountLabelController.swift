//
//  UnreadCountLabelController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/8/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import Foundation

/// Updates the given `UILable` `text` with the current unread count
final class UnreadCountLabelController {
    private let unreadCountLabel: UILabel
    private var observation: NSKeyValueObservation?

    init(unreadCountLabel: UILabel, repository: EkoChannelRepository) {
        self.unreadCountLabel = unreadCountLabel

        updateLabel(count: repository.totalUnreadCount)
        trackUnreadCount(repository: repository)
    }

    private func trackUnreadCount(repository: EkoChannelRepository) {
        observation = repository.observe(\.totalUnreadCount) { [weak self] repository, _ in
            self?.updateLabel(count: repository.totalUnreadCount)
        }
    }

    private func updateLabel(count: UInt) {
        unreadCountLabel.text = count.description
    }
}
