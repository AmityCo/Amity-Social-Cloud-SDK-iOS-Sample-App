//
//  manager.swift
//  SampleApp
//
//  Created by Nishan Niraula on 2/2/22.
//  Copyright © 2022 David Zhang. All rights reserved.
//

import Foundation
import AmitySDK

enum FollowListType {
    case myFollowing(status: AmityFollowQueryOption)
    case myFollower(status: AmityFollowQueryOption)
    case userFollowing(userId: String)
    case userFollower(userId: String)
    
    var isForCurrentUser: Bool {
        switch self {
        case .myFollowing, .myFollower:
            return true
        default:
            return false
        }
    }
}

protocol FollowManagerDelegate: AnyObject {
    func dataDidChange()
}

class FollowManager {
    
    private let userRepo: AmityUserRepository
    private var manager: AmityUserFollowManager {
        return userRepo.followManager
    }
    private var followCollection: AmityCollection<AmityFollowRelationship>?
    private var token: AmityNotificationToken?
    
    var topicSubscriber: AmityTopicSubscription
    
    weak var delegate: FollowManagerDelegate?
    
    private(set) var follows: [AmityFollowRelationship] = []
    
    init() {
        userRepo = AmityUserRepository(client: AmityManager.shared.client!)
        topicSubscriber = AmityTopicSubscription(client: AmityManager.shared.client!)
    }
    
    var type: FollowListType = .myFollower(status: .pending)
    
    func reloadData() {
        manager.clearAmityFollowRelationshipLocalData()
        setup()
    }
    
    func nextPage() {
        if let followCollection = followCollection, followCollection.loadingStatus == .loaded {
            followCollection.nextPage()
        }
    }
    
    private func setup() {
        token?.invalidate()
        
        switch type {
        case .myFollowing(let status):
            followCollection = manager.getMyFollowingList(with: status)
        case .myFollower(let status):
            followCollection = manager.getMyFollowerList(with: status)
        case .userFollowing(let userId):
            followCollection = manager.getUserFollowingList(withUserId: userId)
        case .userFollower(let userId):
            followCollection = manager.getUserFollowerList(withUserId: userId)
        }
        
        token = followCollection?.observe { [weak self] (collection, _, error) in
            var follows: [AmityFollowRelationship] = []
            for follow in collection.allObjects() {
                follows.append(follow)
            }
            self?.follows = follows
            self?.delegate?.dataDidChange()
        }
    }
    
    var followInfoToken: AmityNotificationToken?
    
    func getMyFollowInfo(completion: ((Result<AmityMyFollowInfo, Error>) -> Void)?) {
        
//        followInfoToken?.invalidate()
//        followInfoToken = manager.getMyFollowInfo().observe { [weak self] liveObject, error in
//
//            Log.add(info: "Received as Live Object")
//            guard let object = liveObject.object else { return }
//
//            completion?(.success(object))
//            self?.followInfoToken?.invalidate()
//        }
        
        manager.getMyFollowInfo { (success, info, error) in
            if let info = info {
                completion?(.success(info))
            } else {
                completion?(.failure(error!))
            }
        }
    }
    
    func getUserFollowInfo(userId: String, completion: ((Result<AmityUserFollowInfo, Error>) -> Void)?) {
//        followInfoToken?.invalidate()
//        followInfoToken = manager.getUserFollowInfo(withUserId: userId).observe({ [weak self] liveObject, error in
//            guard let object = liveObject.object, liveObject.dataStatus == .fresh else { return }
//
//            Log.add(info: "Live Object Received: Following: \(object.followingCount), Follower: \(object.followersCount), Status: \(object.status.rawValue)")
//
//            completion?(.success(object))
//        })
        
        manager.getUserFollowInfo(withUserId: userId) { (success, info, error) in
            if let info = info {
                completion?(.success(info))
            } else {
                completion?(.failure(error!))
            }
        }
    }
    
    func acceptUserRequest(userId: String) {
        manager.acceptUserRequest(withUserId: userId) { (success, _, _) in
            print("-> accept \(success ? "success" : "fail")")
        }
    }
    
    func declineUserRequest(userId: String) {
        manager.declineUserRequest(withUserId: userId) { (success, _, error) in
            print("-> decline \(success ? "success" : "fail")")
        }
        
    }
    
    func unfollowUser(userId: String) {
        manager.unfollowUser(withUserId: userId) { (success, _, _) in
            print("-> cancel request \(success ? "success" : "fail")")
        }
    }
    
//    func subscribeEvent(event: AmityFollowEvent, completion: ((Bool) -> Void)?) {
//        guard type.isForCurrentUser else { return }
//
//        let topic = AmityFollowTopic(event: event)
//        topicSubscriber.subscribeTopic(topic) { isSuccess, error in
//            completion?(isSuccess)
//            Log.add(info: "Follow Topic subscribe: \(isSuccess) Error: \(String(describing: error))")
//        }
//    }
//
//    func unsubscribeEvent(event: AmityFollowEvent, completion: ((Bool) -> Void)?) {
//        guard type.isForCurrentUser else { return }
//
//        let topic = AmityFollowTopic(event: event)
//        topicSubscriber.unsubscribeTopic(topic) { isSuccess, error in
//            completion?(isSuccess)
//            Log.add(info: "Follow Topic unsubscribe: \(isSuccess) Error: \(String(describing: error))")
//        }
//    }
}
