//
//  UserRealTimeEventManager.swift
//  SampleApp
//
//  Created by Nishan Niraula on 11/24/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import Foundation

class UserRealTimeEventManager {
    
    enum Element {
        case header
        case posts
    }
    
    var postToken: AmityNotificationToken?
    var userToken: AmityNotificationToken?
    
    let postRepo = AmityPostRepository(client: AmityManager.shared.client!)
    let userRepo = AmityUserRepository(client: AmityManager.shared.client!)
    
    var user: AmityUser
    
    var elements = [UserRealTimeEventManager.Element]()
    var posts = [AmityPost]()
    
    var observeUserChanges: (() -> Void)?
    
    init(user: AmityUser) {
        self.user = user
        self.elements = [.header, .posts]
    }
    
    func getRowCount(element: UserRealTimeEventManager.Element) -> Int {
        switch element {
        case .header:
            return 1
        case .posts:
            return self.posts.count
        }
    }
    
    func subscribeEvent(event: AmityUserEvent, completion: ((Bool) -> Void)?) {
        if event == .user {
            observeCurrentUser()
        }
        
        self.user.subscribeEvent(event) { isSuccess, error in
            completion?(isSuccess)
            Log.add(info: "User Subscribe Event: \(isSuccess) Error: \(String(describing: error))")
        }
    }
    
    func unsubscribeEvent(event: AmityUserEvent, completion: ((Bool) -> Void)?) {
        if event == .user {
            userToken?.invalidate()
        }
        
        self.user.unsubscribeEvent(event) { isSuccess, error in
            completion?(isSuccess)
            Log.add(info: "User unsubscribe Event: \(isSuccess) Error: \(String(describing: error))")
        }
    }
    
    func fetchAllPostsForUser(completion: @escaping () -> Void) {
        let postQueryOption = AmityPostQueryOptions(targetType: .user, targetId: user.userId, sortBy: .lastCreated, deletedOption: .notDeleted, filterPostTypes: nil)
        
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
    
    func observeCurrentUser() {
        userToken?.invalidate()
        userToken = userRepo.getUser(user.userId).observe({ [weak self] liveObject, error in
            
            guard let user = liveObject.object else { return }
            
            self?.user = user
            self?.observeUserChanges?()
        })
    }
}
