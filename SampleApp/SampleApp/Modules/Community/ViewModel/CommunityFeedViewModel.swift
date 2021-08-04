//
//  CommunityFeedViewModel.swift
//  SampleApp
//
//  Created by Sarawoot Khunsri on 1/7/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import UIKit

class CommunityFeedViewModel: ObservableObject {
    
    private let feedRepository = AmityFeedRepository(client: AmityManager.shared.client!)
    private let communityRepository = AmityCommunityRepository(client: AmityManager.shared.client!)
    
    private var token: AmityNotificationToken?
    private var postCollection: AmityCollection<AmityPost>?

    var community: CommunityListModel
    
    var feed = [CommunityPostModel]()
    
    var publishedCount: Int {
        return getPostCount(by: .published)
    }
    
    var reviewingCount: Int {
        return getPostCount(by: .reviewing)
    }
    
    var isDataUpdated: Bool = false
    var feedType: AmityFeedType = .published
    init(community: CommunityListModel) {
        self.community = community
        
    }
    
    func queryFeed(sort: AmityCommunityFeedSortOption, feedType: AmityFeedType, completion: (() -> Void)?) {
        self.feedType = feedType
        if !feed.isEmpty {
            feed = []
            completion?()
        }
        isDataUpdated = false
        postCollection = feedRepository.getCommunityFeed(withCommunityId: community.id, sortBy: sort, includeDeleted: true, feedType: feedType)
        token = postCollection?.observe({ [weak self] (collection, _, _) in
            guard collection.dataStatus == .fresh, let strongSelf = self else { return }
            
//            self?.token?.invalidate()
            Log.add(info: "Feed observed: \(collection.dataStatus.description), post count: \(collection.count())")
            
            var list = [CommunityPostModel]()
            for i in 0..<collection.count() {
                guard let post = collection.object(at: i) else { return }
                let model = CommunityPostModel(postId: post.postId,
                                               postedUserDisplayName: post.postedUser?.displayName,
                                               text: post.data?["text"] as? String,
                                               feedType: post.getFeedType(),
                                               isDeleted: post.isDeleted,
                                               postDataType: post.dataType,
                                               isOwner: post.postedUserId == AmityManager.shared.client?.currentUserId,
                                               createdAt: post.createdAt)
                list.append(model)
            }
            strongSelf.isDataUpdated = true
            strongSelf.feed = list
            completion?()
        })
    }
    
    func post(at indexPath: IndexPath) -> CommunityPostModel {
        return feed[indexPath.row]
    }
    
    func getPostCount(by feedType: AmityFeedType) -> Int {
        return community.getCommunityObject().getPostCount(feedType: feedType)
    }
    
    func approve(post: CommunityPostModel, completion: ((String) -> Void)?) {
        feedRepository.approvePost(withPostId: post.postId) { success, error in
            if success {
                completion?("Success! Approved post")
            } else {
                completion?("Something wrong!, \(error)")
            }
        }
    }
    
    func decline(post: CommunityPostModel, completion: ((String) -> Void)?) {  
        feedRepository.declinePost(withPostId: post.postId) { success, error in
            if success {
                completion?("Success! Decline post")
            } else {
                completion?("Something wrong!, \(error)")
            }
        }
    }
    
    func delete(post: CommunityPostModel, completion: ((String) -> Void)?) {
        if post.isDeleted {
            completion?("Sorry! Post is already deleted")
        } else {
            feedRepository.deletePost(withPostId: post.postId, parentId: nil) { success, error in
                if success {
                    completion?("Success! delete post")
                } else {
                    completion?("Something wrong!, \(error)")
                }
            }
        }
    }
    
}
