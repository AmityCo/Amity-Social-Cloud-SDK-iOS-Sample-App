//
//  UserPostsFeedDataSource.swift
//  SampleApp
//
//  Created by Nishan Niraula on 5/5/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation

enum FeedType {
    case myFeed
    case userFeed
    case singlePost
}

class UserPostsFeedManager {
    
    let client: AmityClient
    let feedRepository: AmityFeedRepository
    
    var postCollection: AmityCollection<AmityPost>?
    var feedCollectionToken: AmityNotificationToken?
    
    var editedPost: AmityPost?
    let userId: String?
    let userName: String?
    var postId: String? // Post id for individual post
    var feedType: FeedType = .myFeed
    
    var reactionCollection: AmityCollection<AmityReaction>?
    var reactionCollectionToken: AmityNotificationToken?
    
    var postObjectToken: AmityNotificationToken?
    var individualPost: AmityPost?
    
    var imageCache = [String: UIImage?]()
    var fileRepository: AmityFileRepository?
    
    var reactionRepository: AmityReactionRepository
    
    var comCategoryCollection: AmityCollection<AmityCommunityCategory>?
    var comCategoryCollectionToken: AmityNotificationToken?
    
    let uploadTracker = DispatchGroup()
    
    var flagger = PostFlagManager()
    var isGlobalFeed = false
    
    var feedSortOption: AmityUserFeedSortOption = .lastCreated
    var includeDeletedPosts = true
    
    lazy var communityRepo: AmityCommunityRepository = {
        let repo = AmityCommunityRepository(client: self.client)
        return repo
    }()
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter
    }()
    
    // Make sure your AmityClient is setup and then setup AmityFeedRepository & AmityPostCreator
    init(client: AmityClient, userId: String?, userName: String? = nil) {
        self.client = client
        self.userId = userId
        self.userName = userName
        self.feedRepository = AmityFeedRepository(client: client)
        self.fileRepository = AmityFileRepository(client: client)
        self.reactionRepository = AmityReactionRepository(client: client)
    }
    
    // MARK:- Feed Observer
    
    // Listen to feed changes. Anytime a post is created, observer
    // would be notified.
    // Note: Retain that AmityNotificationToken
    func observePostsFeedChanges(changeHandler:@escaping ()->()) {
        
        switch feedType {
        case .myFeed, .userFeed:
            
            if isGlobalFeed {
                postCollection = feedRepository.getGlobalFeed()
            } else {
                sortCurrentFeed(option: feedSortOption)
            }
            
            feedCollectionToken = postCollection?.observe({(collection, _, error) in
                Log.add(info: "Post collection observer called")
                changeHandler()
            })
        case .singlePost:
            guard let id = postId else {
                Log.add(info: "Error: Post id is nil while fetching individual post")
                return
            }
            
            let postObject = feedRepository.getPostForPostId(id)
            postObjectToken = postObject.observe({ [weak self] (object, error) in
                self?.individualPost = object.object
                
                changeHandler()
            })
        }
    }
    
    func getPostAtIndex(index: Int) -> AmityPost? {
        switch feedType {
        case .myFeed, .userFeed:
            return postCollection?.object(at: UInt(index))
        case .singlePost:
            return individualPost
        }
    }

    // MARK:- Reaction Observers
    
    func observeReactionsForPost(post: AmityPost?, reaction: String, completion: @escaping ()->()) {
        guard let post = post else { return }
        
        reactionCollectionToken?.invalidate()
        
        reactionCollection = reactionRepository.getReactions(post.postId, referenceType: .post, reactionName: reaction)
        reactionCollectionToken = reactionCollection?.observe({ (collection, change, error) in
            completion()
        })
    }
    
    func observeAllReactionsForPost(post: AmityPost?, completion: @escaping ()->()) {
        guard let post = post else { return }
        
        reactionCollection = reactionRepository.getReactions(post.postId, referenceType: .post, reactionName: nil)
        reactionCollectionToken = reactionCollection?.observe({ (collection, _, error) in
            completion()
        })
    }
    
    func getReactionAtIndex(index: Int) -> AmityReaction? {
        return reactionCollection?.object(at: UInt(index))
    }
    // Creates the post
    func createPost(text: String, images: [UIImage], isFilePost: Bool, communityId: String?, onCompletion: @escaping (_ isSuccess: Bool) -> ()) {
        
        let targetId: String? = communityId == nil ? userId : communityId
        let targetType: AmityPostTargetType = communityId == nil ? .user : .community
        
        if images.isEmpty {
            
            let textBuilder = AmityTextPostBuilder()
            textBuilder.setText(text)
            
            feedRepository.createPost(textBuilder, targetId: targetId, targetType: targetType) { (isSuccess, error) in
                onCompletion(isSuccess)
            }
            
        } else {
            
            if isFilePost {
                Log.add(info: "--- Creating File Post ---")
                Log.add(info: "Uploading Files...")
                
                let dataArr = images.map{ AmityUploadableFile(fileData: $0.jpegData(compressionQuality: 1.0)!, fileName: "my_image_file.jpeg")}
                
                var filesData = [AmityFileData]()
                for file in dataArr {
                    
                    uploadTracker.enter()
                    fileRepository?.uploadFile(file, progress: { progress in
                        Log.add(info: "Progress: \(progress)")
                        
                    }, completion: { [weak self] (data, error) in
                        Log.add(info: "File upload complete")
                        Log.add(info: "File Id: \(String(describing: data?.fileId))")
                        
                        if let fileData = data {
                            Log.add(info: "Uploaded file data is: \(fileData.fileId)")
                            filesData.append(fileData)
                        }
                        self?.uploadTracker.leave()
                    })
                }
                
                uploadTracker.notify(queue: .main) { [weak self] in
                    self?.createFilePost(fileIds: filesData, text: text, targetId: targetId, targetType: targetType, completion: onCompletion)
                }
                
            } else {
                
                Log.add(info: "--- Creating Image Post ---")
                Log.add(info: "Uploading \(images.count) images...")
                
                var imagesData = [AmityImageData]()
                
                for image in images {
                    uploadTracker.enter()
                    fileRepository?.uploadImage(image, progress: { progress in
                        Log.add(info: "Progress: \(progress)")
                    }, completion: { [weak self] (data, error) in
                        if let imgData = data {
                            Log.add(info: "Image upload id: \(imgData.fileId)")
                            imagesData.append(imgData)
                        }
                        
                        Log.add(info: "Image upload complete, Error: \(String(describing: error))")
                        self?.uploadTracker.leave()
                    })
                }
                
                uploadTracker.notify(queue: .main) { [weak self] in
                    self?.createImagePost(fileIds: imagesData, text: text, targetId: targetId, targetType: targetType, completion: onCompletion)
                }
                
            }
        }
    }
    
    func createFilePost(fileIds: [AmityFileData], text: String, targetId: String?, targetType: AmityPostTargetType, completion: @escaping (_ isSuccess: Bool) -> ()) {
        
        let filePostBuilder = AmityFilePostBuilder()
        filePostBuilder.setText(text)
        filePostBuilder.setFileData(fileIds)
        
        feedRepository.createPost(filePostBuilder, targetId: targetId, targetType: targetType) { (isSuccess, error) in
            completion(isSuccess)
        }
    }
    
    func createImagePost(fileIds: [AmityImageData], text: String, targetId: String?, targetType: AmityPostTargetType, completion: @escaping (_ isSuccess: Bool) -> ()) {
        
        let imagePostBuilder = AmityImagePostBuilder()
        imagePostBuilder.setText(text)
        imagePostBuilder.setImageData(fileIds)
        
        feedRepository.createPost(imagePostBuilder, targetId: targetId, targetType: targetType) { (isSuccess, error) in
            completion(isSuccess)
        }
    }
    
    func updatePost(text: String, onCompletion: @escaping (_ isSuccess: Bool)->()) {
        guard let post = editedPost else { return }
        
        // Right now you can only change the text for the image post.
        
        let textBuilder = AmityTextPostBuilder()
        textBuilder.setText(text)
        
        Log.add(info: "Updating post with id: \(post.postId)")
        
        feedRepository.updatePost(withPostId: post.postId, builder: textBuilder) { (isSuccess, error) in
            onCompletion(isSuccess)
        }
        
        editedPost = nil
    }
    
    func deletePost(at index: Int, onCompletion: @escaping (_ isSuccess: Bool)->()) {
        guard let post = postCollection?.object(at: UInt(index)) else { return }
        
        feedRepository.deletePost(withPostId: post.postId, parentId: nil) { (isSuccess, error) in
            onCompletion(isSuccess)
        }
    }
    
    func deleteChildImagePost(at index: Int, onCompletion: @escaping (_ isSuccess: Bool)->()) {
        
        guard let post = postCollection?.object(at: UInt(index)) else { return }
        
        let parentPostId = post.postId
        let childPosts = post.data?["images"] as? [[String: Any]]
        
        let firstChildPost = childPosts?.first
        let childPostId = firstChildPost?["postId"] as? String ?? ""
        
        Log.add(info: "[Delete]: Deleting child post with id: \(childPostId)")
        
        feedRepository.deletePost(withPostId: childPostId, parentId: parentPostId) { (isSuccess, error) in
            onCompletion(isSuccess)
        }
    }
    
    
    func addReactionToPost(at index: Int, reaction: String) {
        
        var selectedPost: AmityPost?
        
        switch feedType {
        case .myFeed, .userFeed:
            selectedPost = postCollection?.object(at: UInt(index))
        case .singlePost:
            selectedPost = individualPost
        }
        
        guard let post = selectedPost else { return }
        
        // If you have already added the same reaction to the post, remove it
        if post.myReactions.contains(reaction) {
            reactionRepository.removeReaction(reaction, referenceId: post.postId, referenceType: .post) { (isSuccess, error) in
                Log.add(info: "[SampleApp]: Reaction Removed \(isSuccess), error: \(String(describing: error))")
            }
        } else {
            reactionRepository.addReaction(reaction, referenceId: post.postId, referenceType: .post) { (isSuccess, error) in
                Log.add(info: "[SampleApp]: Reaction Added \(isSuccess), error: \(String(describing: error))")
            }
        }
    }
    
    func sortCurrentFeed(option: AmityUserFeedSortOption) {
        guard feedType != .singlePost else { return }
        self.feedSortOption = option

        if let id = userId {
            postCollection = feedRepository.getUserFeed(id, sortBy: option, includeDeleted: includeDeletedPosts)
        } else {
            postCollection = feedRepository.getMyFeedSorted(by: option, includeDeleted: includeDeletedPosts)
        }
    }
    
    func loadMorePosts() {
        guard feedType != .singlePost, let hasMorePosts = postCollection?.hasNext, hasMorePosts else { return }
        
        postCollection?.nextPage()
    }
    
    var communityParticipation: AmityCommunityParticipation?
    
    func viewCommunityMembership(index: Int) -> String {
        guard let post = self.getPostAtIndex(index: index) else { return "" }
        
        if post.targetType == "community" {
            communityParticipation = AmityCommunityParticipation(client: AmityManager.shared.client!, andCommunityId: post.targetId)
            if let membership = communityParticipation?.getMember(withId: post.postedUserId) {
                var allData = "Community Membership Data"
                allData += "\nDisplay Name: \(membership.displayName)"
                allData += "\nIs Banned: \(membership.isBanned)"
                allData += "\nMetadata: \(membership.metadata)"
                allData += "\nRoles: \(membership.roles)"
                return allData
            } else {
                return "No Membership Data"
            }
        } else {
            return "This post is not community post"
        }
    }
}
