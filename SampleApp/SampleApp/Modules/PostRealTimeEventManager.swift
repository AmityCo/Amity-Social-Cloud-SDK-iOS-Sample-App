//
//  PostRealTimeEventManager.swift
//  SampleApp
//
//  Created by Nishan Niraula on 11/24/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import Foundation

class PostRealTimeEventManager {
    
    enum Element {
        case header
        case comments
    }
    
    var commentToken: AmityNotificationToken?
    var postToken: AmityNotificationToken?
    
    let commentRepo = AmityCommentRepository(client: AmityManager.shared.client!)
    let postRepo = AmityPostRepository(client: AmityManager.shared.client!)
    
    var elements = [Element]()
    var comments = [AmityComment]()
    
    var post: AmityPost
    let isObserveMode: Bool
    
    var observePostChanges: (() -> Void)?
    
    init(post: AmityPost, isObserveMode: Bool) {
        self.post = post
        self.isObserveMode = isObserveMode
        self.elements = [.header, .comments]
    }
    
    func getRowCount(element: Element) -> Int {
        switch element {
        case .header:
            return 1
        case .comments:
            return self.comments.count
        }
    }
    
    func subscribeEvent(event: AmityPostEvent, completion: ((Bool) -> Void)?) {
        if event == .post {
            observeCurrentPost()
        }
        
        self.post.subscribeEvent(event) { isSuccess, error in
            completion?(isSuccess)
            Log.add(info: "User Subscribe Event: \(isSuccess) Error: \(String(describing: error))")
        }
    }
    
    func unsubscribeEvent(event: AmityPostEvent, completion: ((Bool) -> Void)?) {
        if event == .post {
            postToken?.invalidate()
        }
        
        self.post.unsubscribeEvent(event) { isSuccess, error in
            Log.add(info: "User unsubscribe Event: \(isSuccess) Error: \(String(describing: error))")
            completion?(isSuccess)
        }
    }
    
    func fetchAllCommentsForPost(completion: @escaping () -> Void) {
        commentToken = commentRepo.getCommentsWithReferenceId(post.postId, referenceType: .post, filterByParentId: false, parentId: nil, orderBy: .descending, includeDeleted: false).observe { liveCollection, _, error in
            
            guard liveCollection.dataStatus == .fresh else { return }
            
            var commentList = [AmityComment]()
            for comment in liveCollection.allObjects() {
                commentList.append(comment)
            }
            
            self.comments = commentList
            completion()
        }
    }
    
    func observeCurrentPost() {
        postToken?.invalidate()
        postToken = postRepo.getPostForPostId(post.postId).observe({ [weak self] livePost, error in
            
            guard let post = livePost.object else { return }
            
            self?.post = post
            self?.observePostChanges?()
        })
    }
}
