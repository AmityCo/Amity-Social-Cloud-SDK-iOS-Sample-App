//
//  CommunityRealTimeEventManager.swift
//  SampleApp
//
//  Created by Nishan Niraula on 11/24/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import Foundation

class CommunityRealTimeEventManager {
    
    enum Element {
        case header
        case posts
    }
    
    private var postToken: AmityNotificationToken?
    private var communityToken: AmityNotificationToken?
    private let commRepo = AmityCommunityRepository(client: AmityManager.shared.client!)
    private let postRepo = AmityPostRepository(client: AmityManager.shared.client!)
    
    var elements = [CommunityRealTimeEventManager.Element]()
    var posts = [AmityPost]()
    var community: AmityCommunity
    
    var observeCommunityChanges: (() -> Void)?
        
    init(community: AmityCommunity) {
        self.community = community
        self.elements = [.header, .posts]
    }
    
    func getRowCount(element: CommunityRealTimeEventManager.Element) -> Int {
        switch element {
        case .header:
            return 1
        case .posts:
            return self.posts.count
        }
    }
    
    func subscribeEvent(event: AmityCommunityEvent, completion: ((Bool) -> Void)?) {
        if event == .community {
            observeCurrentCommunity()
        }
        
        self.community.subscribeEvent(event) { isSuccess, error in
            completion?(isSuccess)
            Log.add(info: "User Subscribe Event: \(isSuccess) Error: \(String(describing: error))")
        }
    }
    
    func unsubscribeEvent(event: AmityCommunityEvent, completion: ((Bool) -> Void)?) {
        if event == .community {
            communityToken?.invalidate()
        }
        
        self.community.unsubscribeEvent(event) { isSuccess, error in
            completion?(isSuccess)
            Log.add(info: "User unsubscribe Event: \(isSuccess) Error: \(String(describing: error))")
        }
    }
    
    func fetchAllPostsForCommunity(completion: @escaping () -> Void) {
        let postQueryOption = AmityPostQueryOptions(targetType: .community, targetId: community.communityId, sortBy: .lastCreated, deletedOption: .notDeleted, filterPostTypes: nil)
        
        postToken = postRepo.getPosts(postQueryOption).observe { liveCollection, _, error in
            guard liveCollection.dataStatus == .fresh else { return }
            
            var postList = [AmityPost]()
            for post in liveCollection.allObjects() {
                postList.append(post)
            }
            
            self.posts = postList
            completion()
        }
    }
    
    func observeCurrentCommunity() {
        communityToken?.invalidate()
        communityToken = commRepo.getCommunity(withId: community.communityId).observe { [weak self] liveObject, error in
            guard let community = liveObject.object else { return }
            
            self?.community = community
            self?.observeCommunityChanges?()
        }
    }
}
