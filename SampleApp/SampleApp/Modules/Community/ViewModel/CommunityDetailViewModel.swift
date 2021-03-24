//
//  CommunityDetailViewModel.swift
//  SampleApp
//
//  Created by Michael Abadi on 23/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation
import EkoChat

struct CommunityPostModel: Identifiable, Equatable {
    static func == (lhs: CommunityPostModel, rhs: CommunityPostModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String {
        return postId
    }
    
    let postId: String
    let postedUserDisplayName: String?
    let text: String?
}

// Concrete implementor
class CommunityDetailViewModel: ObservableObject {

    private let feedRepository = EkoFeedRepository(client: EkoManager.shared.client!)
    
    private var token: EkoNotificationToken?
    private var postCollection: EkoCollection<EkoPost>?
    
    private var filter: EkoCommunityQueryFilter = .all
    private var sort: EkoCommunityFeedSortOption = .firstCreated
    var community: CommunityListModel
    
    @Published var feed = [CommunityPostModel]()
    @Published var updateFeed: Bool
        
    init(community: CommunityListModel) {
        self.community = community
        self.feed = []
        self.updateFeed = true
    }
    
    func queryFeed(sort: EkoCommunityFeedSortOption) {
        postCollection = feedRepository.getCommunityFeed(withCommunityId: community.id, sortBy: sort, includeDeleted: false)
        token = postCollection?.observe({ [weak self] (collection, _, _) in
            guard collection.dataStatus == .fresh, let strongSelf = self else { return }
            
            self?.token?.invalidate()
            Log.add(info: "Feed observed: \(collection.dataStatus.description), post count: \(collection.count())")
            
            var list = [CommunityPostModel]()
            for i in 0..<collection.count() {
                guard let post = collection.object(at: i) else { return }
                let model = CommunityPostModel(postId: post.postId, postedUserDisplayName: post.postedUser?.displayName, text: post.data?["text"] as? String)
                list.append(model)
            }
            
            strongSelf.feed = list
            strongSelf.updateFeed.toggle()
        })
    }
    
    func fetchNextPage() {
        postCollection?.nextPage()
    }
}
