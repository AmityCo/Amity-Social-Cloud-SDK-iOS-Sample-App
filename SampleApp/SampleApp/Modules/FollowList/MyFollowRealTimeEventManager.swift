//
//  MyFollowRealTimeEventManager.swift
//  SampleApp
//
//  Created by Nishan Niraula on 2/9/22.
//  Copyright © 2022 David Zhang. All rights reserved.
//

import Foundation
import AmitySDK

class MyFollowRealTimeEventManager {

    /*
    enum Element {
        case header
        case follow
    }
    
    var elements = [MyFollowRealTimeEventManager.Element]()
    var followerList = [AmityFollowRelationship]()
    
    var followQueryOption: AmityFollowQueryOption = .pending
    var isFollowerListType = false
    
    var followCollection: AmityCollection<AmityFollowRelationship>?
    var followCollectionToken: AmityNotificationToken?

    var myFollowInfo: AmityMyFollowInfo?
    var myFollowInfoToken: AmityNotificationToken?
    
    var followManager: AmityUserFollowManager
    var topicSubscriber: AmityTopicSubscription
    
    init() {
        let repo = AmityUserRepository(client: AmityManager.shared.client!)
        followManager = repo.followManager
        topicSubscriber = AmityTopicSubscription(client: AmityManager.shared.client!)
        elements = [.header, .follow]
    }
    
    func getRowCount(element: Element) -> Int {
        switch element {
        case .header:
            return 1
        case .follow:
            return self.followerList.count
        }
    }
    
    func fetchData(completion: @escaping () -> Void) {
        followManager.clearAmityFollowRelationshipLocalData()
        
        followerList = []
        completion()
        
        followCollectionToken?.invalidate()
        
        if isFollowerListType {
            followCollection = followManager.getMyFollowerList(with: followQueryOption)

        } else {
            followCollection = followManager.getMyFollowingList(with: followQueryOption)
        }
        
        followCollectionToken = followCollection?.observe({ [weak self] collection, _, error in
            
            Log.add(info: "Follow Collection Observed. Data Status: \(collection.dataStatus.description)")
            self?.followerList = collection.allObjects()
            
            completion()
        })
    }
    
    func fetchFollowInfo(completion: @escaping () -> Void) {
        myFollowInfoToken?.invalidate()
        myFollowInfoToken = followManager.getMyFollowInfo().observe { [weak self] liveObject, error in
            
            Log.add(info: "Follow Info Updated")
            guard let info = liveObject.object else { return }
            self?.myFollowInfo = info
            
            completion()
        }
    }
    
    func subscribeEvent(event: AmityFollowEvent, completion: ((Bool) -> Void)?) {
        let topic = AmityFollowTopic(event: event)
        topicSubscriber.subscribeTopic(topic) { isSuccess, error in
            completion?(isSuccess)
            Log.add(info: "Follow Topic subscribe: \(isSuccess) Error: \(String(describing: error))")
        }
    }
    
    func unsubscribeEvent(event: AmityFollowEvent, completion: ((Bool) -> Void)?) {
        let topic = AmityFollowTopic(event: event)
        topicSubscriber.unsubscribeTopic(topic) { isSuccess, error in
            completion?(isSuccess)
            Log.add(info: "Follow Topic unsubscribe: \(isSuccess) Error: \(String(describing: error))")
        }
    }
    
    func getFollowInfoDescription() -> String {
        return self.myFollowInfo?.modelDescription ?? ""
    }
    
    func getPageTitle() -> String {
        return isFollowerListType ? "My Follower (\(self.followQueryOption.title))" : "My Following (\(self.followQueryOption.title))"
    }
    
    func fetchNextPage() {
        guard let hasNextPage = followCollection?.hasNext, hasNextPage else { return }
        
        followCollection?.nextPage()
    }
}

extension AmityFollowRelationship {
    
    var followingDescription: String {
        return """
        Display Name: \(self.targetUser?.displayName ?? "-")
        Id: \(self.targetUserId)
        Status: \(self.status.title)
        """
    }
    
    var followerDescription: String {
        return """
        Display Name: \(self.sourceUser?.displayName ?? "-")
        Id: \(self.sourceUserId)
        Status: \(self.status.title)
        """
    }
}

extension AmityMyFollowInfo {
    
    var modelDescription: String {
        return """
        Follow Info:
        
        Follower Count: \(self.followersCount)
        Following Count: \(self.followingCount)
        Pending Count: \(self.pendingCount)
        """
    }
}

extension AmityUserFollowInfo {
    
    var modelDescription: String {
        return """
        Follow Info:
        
        Follower Count: \(self.followersCount)
        Following Count: \(self.followingCount)
        Status: \(self.status.title)
        """
    }
}

class UserFollowRealTimeEventManager: MyFollowRealTimeEventManager {
    
    var userFollowInfo: AmityUserFollowInfo?
    var userFollowInfoToken: AmityNotificationToken?
    
    var userId = ""
    
    override func fetchData(completion: @escaping () -> Void) {
        followManager.clearAmityFollowRelationshipLocalData()
        
        followerList = []
        completion()
        
        followCollectionToken?.invalidate()
        
        if isFollowerListType {
            followCollection = followManager.getUserFollowerList(withUserId: userId)

        } else {
            followCollection = followManager.getUserFollowingList(withUserId: userId)
        }
        
        followCollectionToken = followCollection?.observe({ [weak self] collection, _, error in
            
            Log.add(info: "Follow Collection Observed. Data Status: \(collection.dataStatus.description)")
            self?.followerList = collection.allObjects()
            
            completion()
        })
    }
    
    override func fetchFollowInfo(completion: @escaping () -> Void) {
        userFollowInfoToken?.invalidate()
        userFollowInfoToken = followManager.getUserFollowInfo(withUserId: userId).observe { [weak self] liveObject, error in
            
            guard let info = liveObject.object else { return }
            self?.userFollowInfo = info
            
            completion()
        }
    }
    
    override func getFollowInfoDescription() -> String {
        return userFollowInfo?.modelDescription ?? ""
    }
    
    override func getPageTitle() -> String {
        return self.isFollowerListType ? "Follower" : "Following"
    }
    
    */
}
