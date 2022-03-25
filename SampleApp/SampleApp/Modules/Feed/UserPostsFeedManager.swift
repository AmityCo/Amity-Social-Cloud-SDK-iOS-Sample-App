//
//  UserPostsFeedDataSource.swift
//  SampleApp
//
//  Created by Nishan Niraula on 5/5/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import AmitySDK
import UIKit

enum FeedType {
    case globalFeed
    case customPostRankingGlobalFeed
    case myFeed
    case userFeed
    case singlePost
    case community
}

class UserPostsFeedManager {
    
    let client: AmityClient
    let feedRepository: AmityFeedRepository
    let postRepository: AmityPostRepository
    let pollRepository: AmityPollRepository
    
    var postCollection: AmityCollection<AmityPost>?
    var feedCollectionToken: AmityNotificationToken?
    
    var communityParticipation: AmityCommunityParticipation?
    
    var editedPost: AmityPost?
    let userId: String?
    let userName: String?
    var community: CommunityListModel?
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
    
    var feedSortOption: AmityPostQuerySortOption = .lastCreated
    var feedSortCommunityOption: FeedItemDefaultAction = .publishedAndSortLastCreated
    var includeDeletedPosts = true
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter
    }()
    
    var postFeedType: AmityFeedType = .published
    var sortCommunityHandler: (() -> Void)?
    
    // Make sure your AmityClient is setup and then setup AmityFeedRepository & AmityPostCreator
    init(client: AmityClient, userId: String?, userName: String? = nil, community: CommunityListModel? = nil) {
        self.client = client
        self.userId = userId
        self.userName = userName
        self.community = community
        self.feedRepository = AmityFeedRepository(client: client)
        self.postRepository = AmityPostRepository(client: client)
        self.pollRepository = AmityPollRepository(client: client)
        self.fileRepository = AmityFileRepository(client: client)
        self.reactionRepository = AmityReactionRepository(client: client)
    }
    
    // MARK:- Feed Observer
    
    // Listen to feed changes. Anytime a post is created, observer
    // would be notified.
    // Note: Retain that AmityNotificationToken
    func observePostsFeedChanges(changeHandler:@escaping ()->()) {
                
        switch feedType {
            
        case .globalFeed:
            postCollection = feedRepository.getGlobalFeed()
            feedCollectionToken?.invalidate()
            feedCollectionToken = postCollection?.observe({(collection, _, error) in
                Log.add(info: "Post collection observer called")
                changeHandler()
            })
        case .customPostRankingGlobalFeed:
            postCollection = feedRepository.getCustomPostRankingGlobalfeed()
            feedCollectionToken?.invalidate()
            feedCollectionToken = postCollection?.observe({(collection, _, error) in
                Log.add(info: "Post collection observer called")
                changeHandler()
            })
        case .myFeed, .userFeed, .community:
            sortCurrentFeed(option: feedSortOption)
            
            feedCollectionToken?.invalidate()
            feedCollectionToken = postCollection?.observe({(collection, _, error) in
                Log.add(info: "Post collection observer called")
                changeHandler()
            })
        case .singlePost:
            guard let id = postId else {
                Log.add(info: "Error: Post id is nil while fetching individual post")
                return
            }
            
            let postObject = postRepository.getPostForPostId(id)
            postObjectToken?.invalidate()
            postObjectToken = postObject.observe({ [weak self] (object, error) in
                self?.individualPost = object.object
                
                changeHandler()
            })
        }
    }
    
    func getPostAtIndex(index: Int) -> AmityPost? {
        switch feedType {
        case .globalFeed, .customPostRankingGlobalFeed, .myFeed, .userFeed, .community:
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
    func createPost(text: String?,
                    images: [UIImage],
                    videos: [URL],
                    isFilePost: Bool,
                    communityId: String?,
                    streamId: String?,
                    metadata: [String: Any]?,
                    mentionees: AmityMentioneesBuilder?,
                    onCompletion: @escaping (_ isSuccess: Bool) -> Void) {
        
        let targetId: String? = communityId == nil ? userId : communityId
        let targetType: AmityPostTargetType = communityId == nil ? .user : .community
        
        if !images.isEmpty, !videos.isEmpty {
            print("This app does not support create post with both video and image attached.")
            onCompletion(false)
        }
        
        if let streamId = streamId, !streamId.isEmpty {
            let builder = AmityLiveStreamPostBuilder(streamId: streamId, text: text)
            if let mentionees = mentionees, let metadata = metadata {
                postRepository.createPost(builder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees) { post, error in
                    let isSuccess = post != nil
                    onCompletion(isSuccess)
                }
            } else {
                postRepository.createPost(builder, targetId: targetId, targetType: targetType) { post, error in
                    let isSuccess = post != nil
                    onCompletion(isSuccess)
                }
            }
        } else if images.isEmpty, videos.isEmpty {
            
            // Text Post
            
            let textBuilder = AmityTextPostBuilder()
            if let text = text {
                textBuilder.setText(text)
            }
            
            if let mentionees = mentionees, let metadata = metadata {
                postRepository.createPost(textBuilder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees) { (post, error) in
                    let isSuccess = post != nil
                    onCompletion(isSuccess)
                }
            } else {
                postRepository.createPost(textBuilder, targetId: targetId, targetType: targetType) { (post, error) in
                    let isSuccess = post != nil
                    onCompletion(isSuccess)
                }
            }
        } else if isFilePost {
            
            // File Post
            
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
                self?.createFilePost(fileIds: filesData, text: text, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees, completion: onCompletion)
            }
            
        } else if !images.isEmpty {
            
            // Image Post
            
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
                self?.createImagePost(fileIds: imagesData, text: text, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees, completion: onCompletion)
            }
            
        } else if !videos.isEmpty {
            
            // Video Post
            
            Log.add(info: "--- Creating Video Post ---")
            Log.add(info: "Uploading \(videos.count) videos...")
            
            var videosData: [AmityVideoData] = []
            
            for videoUrl in videos {
                uploadTracker.enter()
                fileRepository?.uploadVideo(with: videoUrl, progress: { progress in
                    Log.add(info: "Progress: \(progress)")
                }, completion: { [weak self] (data, error) in
                    if let videoData = data {
                        Log.add(info: "Video upload id: \(videoData.fileId)")
                        videosData.append(videoData)
                    }
                    if let error = error {
                        Log.add(info: "Video upload complete, Error: \(String(describing: error))")
                    }
                    self?.uploadTracker.leave()
                })
            }
            
            uploadTracker.notify(queue: .main) { [weak self] in
                if !videosData.isEmpty {
                    self?.createVideoPost(videosData: videosData, text: text, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees, completion: onCompletion)
                } else {
                    onCompletion(false)
                }
            }
            
        } else {
            assertionFailure("Unhandle create post case.")
        }
        
    }
    
    func createFilePost(fileIds: [AmityFileData], text: String?, targetId: String?, targetType: AmityPostTargetType, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?, completion: @escaping (_ isSuccess: Bool) -> ()) {
        
        let filePostBuilder = AmityFilePostBuilder()
        if let text = text {
            filePostBuilder.setText(text)
        }
        filePostBuilder.setFiles(fileIds)
        
        if let mentionees = mentionees {
            postRepository.createPost(filePostBuilder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees) { (post, error) in
                let isSuccess = post != nil
                completion(isSuccess)
            }
        } else {
            postRepository.createPost(filePostBuilder, targetId: targetId, targetType: targetType) { (post, error) in
                let isSuccess = post != nil
                completion(isSuccess)
            }
        }
    }
    
    func createImagePost(fileIds: [AmityImageData], text: String?, targetId: String?, targetType: AmityPostTargetType,metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?, completion: @escaping (_ isSuccess: Bool) -> ()) {
        
        let imagePostBuilder = AmityImagePostBuilder()
        if let text = text {
            imagePostBuilder.setText(text)
        }
        imagePostBuilder.setImages(fileIds)
        
        if let mentionees = mentionees {
            postRepository.createPost(imagePostBuilder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees) { (post, error) in
                let isSuccess = post != nil
                completion(isSuccess)
            }
        } else {
            postRepository.createPost(imagePostBuilder, targetId: targetId, targetType: targetType) { (post, error) in
                let isSuccess = post != nil
                completion(isSuccess)
            }
        }
    }
    
    func createVideoPost(videosData: [AmityVideoData], text: String?, targetId: String?, targetType: AmityPostTargetType, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?, completion: @escaping (_ isSuccess: Bool) -> ()) {
        
        let videoPostBuilder = AmityVideoPostBuilder()
        if let text = text {
            videoPostBuilder.setText(text)
        }
        videoPostBuilder.setVideos(videosData)
        
        if let mentionees = mentionees {
            postRepository.createPost(videoPostBuilder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees) { (post, error) in
                let isSuccess = post != nil
                completion(isSuccess)
            }
        } else {
            postRepository.createPost(videoPostBuilder, targetId: targetId, targetType: targetType) { (post, error) in
                let isSuccess = post != nil
                completion(isSuccess)
            }
        }
    }
    
    // MARK: - Poll
    func createPollPost(text: String?,
                        numOptions: String?,
                        numDayToClose: String?,
                        isMultipleVote: Bool,
                        communityId: String?,
                        metadata: [String: Any]?,
                        mentionees: AmityMentioneesBuilder?,
                        completion: @escaping (_ isSuccess: Bool) -> ()) {
        guard let text = text, let options = Int(numOptions ?? "2"), (options > 1 && options <= 10), let numDay = Int(numDayToClose ?? "1") else {
            completion(false)
            return
        }
        
        let targetId: String? = communityId == nil ? userId : communityId
        let targetType: AmityPostTargetType = communityId == nil ? .user : .community
        
        let milliSec = numDay * (24 * 60 * 60 * 1000)
        
        let pollBuilder = AmityPollCreationBuilder()
        
        pollBuilder.setQuestion(text)
        pollBuilder.setTimeToClosePoll(milliSec)
        pollBuilder.setAnswerType(isMultipleVote ? .multiple : .single)
        
        for index in 1...options {
            pollBuilder.setAnswer("Poll Option \(index)")
        }
        
        pollRepository.createPoll(pollBuilder) { [weak self] pollId, error in
            if error == nil {
                guard let pollId = pollId else { return }
                let builder = AmityPollPostBuilder()
                builder.setText(text)
                builder.setPollId(pollId)
                if let mentionees = mentionees, let metadata = metadata {
                    self?.postRepository.createPost(builder, targetId: targetId, targetType: targetType, metadata: metadata, mentionees: mentionees) { post, error in
                        let isSuccess = post != nil
                        completion(isSuccess)
                    }
                } else {
                    self?.postRepository.createPost(builder, targetId: targetId, targetType: targetType) { post, error in
                        let isSuccess = post != nil
                        completion(isSuccess)
                    }
                }
            }
        }
    }
    
    func votePoll(withPollid pollId: String, answerIds: [String], onCompletion: @escaping (_ isSuccess: Bool)->()) {
        pollRepository.votePoll(withId: pollId, answerIds: answerIds) { isSuccess, error in
            onCompletion(isSuccess)
        }
    }
    
    func closedPoll(withPollId pollId: String, onCompletion: @escaping (_ isSuccess: Bool)->() ) {
        pollRepository.closePoll(withId: pollId) { isSuccess, error in
            onCompletion(isSuccess)
        }
    }
    
    func updatePost(text: String?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?, onCompletion: @escaping (_ isSuccess: Bool)->()) {
        
        guard let post = editedPost else { return }
        
        // Right now you can only change the text for the image post.
        
        let textBuilder = AmityTextPostBuilder()
        if let text = text {
            textBuilder.setText(text)
        }
        
        Log.add(info: "Updating post with id: \(post.postId)")
        
        if let mentionees = mentionees {
            postRepository.updatePost(withPostId: post.postId, builder: textBuilder, metadata: metadata, mentionees: mentionees) { (post, error) in
                let isSuccess = post != nil
                onCompletion(isSuccess)
            }
        } else {
            postRepository.updatePost(withPostId: post.postId, builder: textBuilder) { (post, error) in
                let isSuccess = post != nil
                onCompletion(isSuccess)
            }
        }
        
        editedPost = nil
    }
    
    func deletePost(at index: Int, hardDelete: Bool, onCompletion: @escaping (_ isSuccess: Bool)->()) {
        guard let post = postCollection?.object(at: UInt(index)) else { return }
        postRepository.deletePost(withPostId: post.postId, parentId: nil, hardDelete: hardDelete) { (isSuccess, error) in
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
        
        postRepository.deletePost(withPostId: childPostId, parentId: parentPostId, hardDelete: false) { (isSuccess, error) in
            onCompletion(isSuccess)
        }
        
    }
    
    
    func addReactionToPost(at index: Int, reaction: String) {
        
        var selectedPost: AmityPost?
        
        switch feedType {
        case .globalFeed, .customPostRankingGlobalFeed, .myFeed, .userFeed, .community:
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
    
    func sortCurrentFeed(option: AmityPostQuerySortOption) {
        guard feedType != .singlePost else { return }
        self.feedSortOption = option

        switch feedType {
        case .myFeed, .userFeed:
            if let id = userId {
                postCollection = feedRepository.getUserFeed(id, sortBy: option, includeDeleted: includeDeletedPosts)
            } else {
                postCollection = feedRepository.getMyFeedSorted(by: option, includeDeleted: includeDeletedPosts)
            }
        case .community:
            guard let communityId = community?.communityId else { return }
            let communityOption: AmityPostQuerySortOption = option == .firstCreated ? .firstCreated:.lastCreated
            postCollection = feedRepository.getCommunityFeed(withCommunityId: communityId, sortBy: communityOption, includeDeleted: includeDeletedPosts, feedType: postFeedType)
        case .globalFeed, .customPostRankingGlobalFeed, .singlePost:
            break
        }
    }
    
    func sortCurrentFeedCommunity(option: FeedItemDefaultAction) {
        guard feedType != .singlePost else { return }
        switch option {
        case .publishedAndSortFirstCreated:
            self.feedSortOption = .firstCreated
            self.postFeedType = .published
        case .publishedAndSortLastCreated:
            self.feedSortOption = .lastCreated
            self.postFeedType = .published
        case .reviewingAndSortFirstCreated:
            self.feedSortOption = .firstCreated
            self.postFeedType = .reviewing
        case .reviewingAndSortLastCreated:
            self.feedSortOption = .lastCreated
            self.postFeedType = .reviewing
        
        default:
            return
        }
        
        switch feedType {
        case .community:
            guard let communityId = community?.communityId else { return }
            let communityOption: AmityPostQuerySortOption = feedSortOption == .firstCreated ? .firstCreated:.lastCreated
            postCollection = feedRepository.getCommunityFeed(withCommunityId: communityId, sortBy: communityOption, includeDeleted: includeDeletedPosts, feedType: postFeedType)
            sortCommunityHandler?()
        default:
            return
        }
    }
    
    func loadMorePosts() {
        guard feedType != .singlePost, let hasMorePosts = postCollection?.hasNext, hasMorePosts else { return }
        
        postCollection?.nextPage()
    }
    
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
    
    // pending posts
    func approve(post: AmityPost?, completion: ((String) -> Void)?) {
        guard let post = post else { return }
        postRepository.approvePost(withPostId: post.postId) { success, error in
            if success {
                completion?("Success! Approved post")
            } else {
                completion?("Something wrong!, \(error)")
            }
        }
    }
    
    func decline(post: AmityPost?, completion: ((String) -> Void)?) {
        guard let post = post else { return }
        postRepository.declinePost(withPostId: post.postId) { success, error in
            if success {
                completion?("Success! Decline post")
            } else {
                completion?("Something wrong!, \(error)")
            }
        }
    }
}
