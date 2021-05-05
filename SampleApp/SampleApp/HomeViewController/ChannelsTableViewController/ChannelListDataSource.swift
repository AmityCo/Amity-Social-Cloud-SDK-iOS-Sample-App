//
//  ChannelListDataSource.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/26/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import AmitySDK

final class ChannelListDataSource {
    
    /*
     AmityChannelRepository class deals with all channel related operation
     */
    private let repository: AmityChannelRepository
    
    /*
     Bind your AmityChannel Collection to AmityNotificationToken. Retain AmityNotificationToken
     */
    private var channelsCollection: AmityCollection<AmityChannel>?
    private var channelsToken: AmityNotificationToken? {
        didSet {
            oldValue?.invalidate()
        }
    }
    
    // Observer which notifies changes to UI
    weak var dataSourceObserver: DataSourceListener?
    
    
    init(channelRepository: AmityChannelRepository) {
        self.repository = channelRepository
    }
    
    /*
     This method builds the channel. Then uses AmityChannelRepository instance to fetch channel collection & observe it.
     */
    func fetchChannels(channelType: AmityChannelType, channelFilter: AmityChannelQueryFilter, includingTags: [String], excludingTags: [String], channelTypeName: Set<String> = Set(arrayLiteral: "standard", "private", "live", "community", "conversation")) {
        
        switch channelType {
        case .private:
            let builder = AmityPrivateChannelQueryBuilder(includingTags: includingTags, excludingTags: excludingTags, includeDeleted: false)
            channelsCollection = repository.getChannels().privateType(with: builder).query()
        case .standard:
            let builder = AmityStandardChannelQueryBuilder(channelQueryFilter: channelFilter, includingTags: includingTags, excludingTags: excludingTags, includeDeleted: false)
            channelsCollection = repository.getChannels().standardType(with: builder).query()
        case .byTypes:
            let builderSet: Set<String> = channelTypeName
            let builder = AmityByTypesChannelQueryBuilder(types: builderSet, channelQueryFilter: channelFilter, includingTags: includingTags, excludingTags: excludingTags, includeDeleted: false)
            channelsCollection = repository.getChannels().byTypes(with: builder).query()
        case .broadcast:
            let builder = AmityBroadcastChannelQueryBuilder(channelQueryFilter: channelFilter, includingTags: includingTags, excludingTags: excludingTags, includeDeleted: false)
            channelsCollection = repository.getChannels().broadcast(with: builder).query()
        case .conversation:
            let builder = AmityConversationChannelQueryBuilder(includingTags: nil, excludingTags: nil, includeDeleted: false)
            channelsCollection = repository.getChannels().conversation(with: builder).query()
            
        case .live:
            let builder = AmityLiveChannelQueryBuilder(includingTags: includingTags, excludingTags: excludingTags, includeDeleted: false)
            channelsCollection = repository.getChannels().liveType(with: builder).query()
            
        case .community:
            let builder = AmityCommunityChannelQueryBuilder(filter: channelFilter, includingTags: includingTags, excludingTags: excludingTags, includeDeleted: false)
            channelsCollection = repository.getChannels().communityType(with: builder).query()
            
        @unknown default:
            fatalError()
        }
        
        dataSourceObserver?.didUpdateDataSource()
        channelsToken = channelsCollection?.observe { [weak self] _, _, _ in
            
            // Do your changes when you observe changes to channels
            self?.dataSourceObserver?.didUpdateDataSource()
        }
    }
    
    /*
     AmityCollection contains count method which returns number of channels present
     in collection.
     */
    func numberOfChannels() -> Int {
        return Int(channelsCollection?.count() ?? 0)
    }
    
    /*
     Returns channels to display in UI.
     */
    func channel(for indexPath: IndexPath) -> AmityChannel? {
        if let channelsCollection = self.channelsCollection, channelsCollection.count() > indexPath.row {
            return channelsCollection.object(at: UInt(indexPath.row))
        } else {
            channelsCollection?.nextPage()
            return nil
        }
    }
    
    /*
     AmityCollection handles pagination out of the box. Just call nextPage() or previousPage() on collection object.
     */
    func fetchMoreChannels() {
        channelsCollection?.nextPage()
    }
}
