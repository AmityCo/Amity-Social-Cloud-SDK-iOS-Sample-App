//
//  ChannelListDataSource.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/26/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import EkoChat

final class ChannelListDataSource {
    
    /*
     EkoChannelRepository class deals with all channel related operation
     */
    private let repository: EkoChannelRepository
    
    /*
     Bind your EkoChannel Collection to EkoNotificationToken. Retain EkoNotificationToken
     */
    private var channelsCollection: EkoCollection<EkoChannel>?
    private var channelsToken: EkoNotificationToken? {
        didSet {
            oldValue?.invalidate()
        }
    }
    
    // Observer which notifies changes to UI
    weak var dataSourceObserver: DataSourceListener?
    
    
    init(channelRepository: EkoChannelRepository) {
        self.repository = channelRepository
    }
    
    /*
     This method builds the channel. Then uses EkoChannelRepository instance to fetch channel collection & observe it.
     */
    func fetchChannels(channelType: EkoChannelType, channelFilter: EkoChannelQueryFilter, includingTags: [String], excludingTags: [String], channelTypeName: Set<String> = Set(arrayLiteral: "standard", "private", "live", "community", "conversation")) {
        
        switch channelType {
        case .private:
            let builder = EkoPrivateChannelQueryBuilder(includingTags: includingTags, excludingTags: excludingTags, includeDeleted: false)
            channelsCollection = repository.channelCollection().privateType(with: builder).query()
        case .standard:
            let builder = EkoStandardChannelQueryBuilder(channelQueryFilter: channelFilter, includingTags: includingTags, excludingTags: excludingTags, includeDeleted: false)
            channelsCollection = repository.channelCollection().standardType(with: builder).query()
        case .byTypes:
            let builderSet: Set<String> = channelTypeName
            let builder = EkoByTypesChannelQueryBuilder(types: builderSet, channelQueryFilter: channelFilter, includingTags: includingTags, excludingTags: excludingTags, includeDeleted: false)
            channelsCollection = repository.channelCollection().byTypes(with: builder).query()
        case .broadcast:
            let builder = EkoBroadcastChannelQueryBuilder(channelQueryFilter: channelFilter, includingTags: includingTags, excludingTags: excludingTags, includeDeleted: false)
            channelsCollection = repository.channelCollection().broadcast(with: builder).query()
        case .conversation:
            let builder = EkoConversationChannelQueryBuilder(includingTags: nil, excludingTags: nil, includeDeleted: false)
            channelsCollection = repository.channelCollection().conversation(with: builder).query()
            
        case .live:
            let builder = EkoLiveChannelQueryBuilder(includingTags: includingTags, excludingTags: excludingTags, includeDeleted: false)
            channelsCollection = repository.channelCollection().liveType(with: builder).query()
            
        case .community:
            let builder = EkoCommunityChannelQueryBuilder(filter: .userIsMember, includingTags: includingTags, excludingTags: excludingTags, includeDeleted: false)
            channelsCollection = repository.channelCollection().communityType(with: builder).query()
            
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
     EkoCollection contains count method which returns number of channels present
     in collection.
     */
    func numberOfChannels() -> Int {
        return Int(channelsCollection?.count() ?? 0)
    }
    
    /*
     Returns channels to display in UI.
     */
    func channel(for indexPath: IndexPath) -> EkoChannel? {
        if let channelsCollection = self.channelsCollection, channelsCollection.count() > indexPath.row {
            return channelsCollection.object(at: UInt(indexPath.row))
        } else {
            channelsCollection?.nextPage()
            return nil
        }
    }
    
    /*
     EkoCollection handles pagination out of the box. Just call nextPage() or previousPage() on collection object.
     */
    func fetchMoreChannels() {
        channelsCollection?.nextPage()
    }
}
