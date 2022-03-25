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
    func fetchChannels(
        channelType: AmityChannelType,
        channelFilter: AmityChannelQueryFilter,
        includingTags: [String],
        excludingTags: [String],
        channelTypes: Set<String> = Set([
            AmityChannelQueryType.standard,
            AmityChannelQueryType.private,
            AmityChannelQueryType.live,
            AmityChannelQueryType.community,
            AmityChannelQueryType.conversation])
    ) {
                
        let query = AmityChannelQuery()
        
        query.includingTags = includingTags
        query.excludingTags = excludingTags
        query.includeDeleted = false
        
        switch channelType {
        case .private:
            query.types = [AmityChannelQueryType.private]
        case .standard:
            query.types = [AmityChannelQueryType.standard]
        case .unknown:
            query.types = channelTypes
        case .broadcast:
            query.types = [AmityChannelQueryType.broadcast]
        case .conversation:
            query.types = [AmityChannelQueryType.conversation]
        case .live:
            query.types = [AmityChannelQueryType.live]
        case .community:
            query.types = [AmityChannelQueryType.community]
        @unknown default:
            fatalError()
        }
        
        channelsCollection = repository.getChannels(with: query)
        
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
