//
//  MembershipListDataSource.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/10/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import AmitySDK

final class MembershipListDataSource {
    private unowned var client: AmityClient
    private let channelId: String

    weak var dataSourceObserver: DataSourceListener?

    private var membershipsCollection: AmityCollection<AmityChannelMember>?
    private var channelObject: AmityObject<AmityChannel>?

    private var membershipsToken: AmityNotificationToken?
    private var channelToken: AmityNotificationToken?
    private var channelModeration: AmityChannelModeration
    
    init(client: AmityClient, channelId: String) {
        self.client = client
        self.channelId = channelId
        
        channelModeration = AmityChannelModeration(client: client, andChannel: channelId)

        setupObserver()
    }

    private func setupObserver() {
        let channelRepository: AmityChannelRepository = AmityChannelRepository(client: client)
        channelObject = channelRepository.getChannel(channelId)

        guard let channel: AmityChannel = channelObject?.object else { return }
        membershipsCollection = channel.participation.getMembers(filter: .all, sortBy: .lastCreated, roles: [])

        channelToken = channelObject?.observe { [weak self] _, _  in
            self?.dataSourceObserver?.didUpdateDataSource()
        }

        membershipsToken = membershipsCollection?.observe { [weak self] _, _, _ in
            self?.dataSourceObserver?.didUpdateDataSource()
        }
    }
    
    func numberOfMemberships() -> Int {
        return Int(membershipsCollection?.count() ?? 0)
    }

    func membership(for indexPath: IndexPath) -> AmityChannelMember? {
        if
            let membershipsCollection = self.membershipsCollection,
            membershipsCollection.count() > indexPath.row {
            return membershipsCollection.object(at: UInt(indexPath.row))
        } else {
            membershipsCollection?.nextPage()
            return nil
        }
    }
    
    public func filterMembers(by role: String?) {
        membershipsToken?.invalidate()
        guard let channel: AmityChannel = channelObject?.object else { return }
        
        if let userRole = role {
            membershipsCollection = channel.participation.getMembers(filter: .all, sortBy: .lastCreated, roles: [userRole])
        } else {
            membershipsCollection = channel.participation.getMembers(filter: .all, sortBy: .lastCreated, roles: [])
        }
        
        membershipsToken = membershipsCollection?.observe { [weak self] _, _, _ in
            self?.dataSourceObserver?.didUpdateDataSource()
        }
    }
    
    public func addRole(for indexPath: IndexPath, role: String) {
        guard let member = membership(for: indexPath) else { return }
        
        channelModeration.addRole(role, userIds: [member.userId]) { [weak self] _,_ in
            self?.dataSourceObserver?.didUpdateDataSource()
        }
    }
    
    public func removeRole(for indexPath: IndexPath, role: String) {
        guard let member = membership(for: indexPath) else { return }
        
        channelModeration.removeRole(role, userIds: [member.userId]) { [weak self] _,_ in
            self?.dataSourceObserver?.didUpdateDataSource()
        }
    }
}
