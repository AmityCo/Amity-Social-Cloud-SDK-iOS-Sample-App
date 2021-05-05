//
//  ChannelTagsDataSource.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/19/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import AmitySDK

final class ChannelTagsDataSource {
    private unowned var client: AmityClient
    private let channelId: String

    weak var dataSourceObserver: DataSourceListener?

    private var membershipsCollection: AmityCollection<AmityChannelMember>?
    private var channelObject: AmityObject<AmityChannel>?
    private var channelToken: AmityNotificationToken?

    init(client: AmityClient, channelId: String) {
        self.client = client
        self.channelId = channelId

        setupObserver()
    }

    private func setupObserver() {
        let channelRepository: AmityChannelRepository = AmityChannelRepository(client: client)
        channelObject = channelRepository.getChannel(channelId)

        guard let channel: AmityChannel = channelObject?.object else { return }
        membershipsCollection = channel.participation.getMembers(filter: .all, sortBy: .lastCreated, roles: [])

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
            let channel: AmityChannel = channelObject?.object else { return nil }

        return (channel.tags as? [String])?[indexPath.row]
    }
}
