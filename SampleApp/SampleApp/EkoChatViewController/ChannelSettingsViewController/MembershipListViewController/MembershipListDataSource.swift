//
//  MembershipListDataSource.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/10/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import EkoChat

final class MembershipListDataSource {
    private unowned var client: EkoClient
    private let channelId: String

    weak var dataSourceObserver: DataSourceListener?

    private var membershipsCollection: EkoCollection<EkoChannelMembership>?
    private var channelObject: EkoObject<EkoChannel>?

    private var membershipsToken: EkoNotificationToken?
    private var channelToken: EkoNotificationToken?
    private var channelModeration: EkoChannelModeration
    
    init(client: EkoClient, channelId: String) {
        self.client = client
        self.channelId = channelId
        
        channelModeration = EkoChannelModeration(client: client, andChannel: channelId)

        setupObserver()
    }

    private func setupObserver() {
        let channelRepository: EkoChannelRepository = EkoChannelRepository(client: client)
        channelObject = channelRepository.getChannel(channelId)

        guard let channel: EkoChannel = channelObject?.object else { return }
        membershipsCollection = channel.participation.memberships

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

    func membership(for indexPath: IndexPath) -> EkoChannelMembership? {
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
        guard let channel: EkoChannel = channelObject?.object else { return }
        
        if let userRole = role {
            membershipsCollection = channel.participation.memberships(for: .all, sortBy: .firstCreated, roles: [userRole])
        } else {
            membershipsCollection = channel.participation.memberships
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
