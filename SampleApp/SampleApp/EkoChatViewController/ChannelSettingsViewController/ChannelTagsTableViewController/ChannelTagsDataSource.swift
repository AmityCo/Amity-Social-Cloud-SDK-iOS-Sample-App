//
//  ChannelTagsDataSource.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/19/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import EkoChat

final class ChannelTagsDataSource {
    private unowned var client: EkoClient
    private let channelId: String

    weak var dataSourceObserver: DataSourceListener?

    private var membershipsCollection: EkoCollection<EkoChannelMembership>?
    private var channelObject: EkoObject<EkoChannel>?
    private var channelToken: EkoNotificationToken?

    init(client: EkoClient, channelId: String) {
        self.client = client
        self.channelId = channelId

        setupObserver()
    }

    private func setupObserver() {
        let channelRepository: EkoChannelRepository = EkoChannelRepository(client: client)
        channelObject = channelRepository.getChannel(channelId)

        guard let channel: EkoChannel = channelObject?.object else { return }
        membershipsCollection = channel.participation.memberships

        channelToken = channelObject?.observe { [weak self] _, _ in
            self?.dataSourceObserver?.didUpdateDataSource()
        }
    }

    func numberOfTags() -> Int {
        return channelObject?.object?.tags.count ?? 0
    }

    func tag(for indexPath: IndexPath) -> String? {
        guard
            numberOfTags() > indexPath.row,
            let channel: EkoChannel = channelObject?.object else { return nil }

        return (channel.tags as? [String])?[indexPath.row]
    }
}
