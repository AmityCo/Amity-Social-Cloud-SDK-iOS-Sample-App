//
//  UserPostsFeedManager+Extension.swift
//  SampleApp
//
//  Created by Nishan Niraula on 7/14/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation

// Helper class for managing view specific code for feed.
// Look into "UserPostsFeedManager.swift" for sdk specific implementation.
extension UserPostsFeedManager {
    
    func getFeedItemType(for post: AmityPost) -> FeedItemType {
        if let _ = post.data?["images"] as? [[String: Any]] {
            return .image
        }
        
        return .text
    }
    
    private func createTextFeedModel(post: AmityPost?) -> TextFeedModel {
        let textData = post?.data?["text"] as? String ?? "-"
        let userName = post?.postedUser?.displayName ?? "No Name"
        
        var dateStr = "-"
        if let date = post?.createdAt {
            dateStr = dateFormatter.string(from: date)
        }
        
        let postModel = TextFeedModel(text: textData, userName: userName, date: dateStr)
        return postModel
    }
    
    // To determine post reactions
    func getReadableDate(date: Date?) -> String {
        if let date = date {
            return dateFormatter.string(from: date)
        } else {
            return ""
        }
    }
    
    func downloadImage(fileUrl: String, completion: @escaping (UIImage?) -> ()) {
        
        guard !fileUrl.isEmpty else { return }
        
        if let cachedImage = imageCache[fileUrl] {
            completion(cachedImage)
            return
        }
        
        Log.add(info: "Downloading Image.....")
        fileRepository?.downloadImageAsData(fromURL: fileUrl, size: .small, completion: { [weak self] (image, size, error) in
            
            if let err = error {
                Log.add(info: "Image download error: \(err)")
                return
            }
            
            Log.add(info: "Image download success..")
            
            self?.imageCache[fileUrl] = image
            completion(image)
        })
    }
    
    func prepareToEditPost(at index: Int) {
        var selectedPost: AmityPost?
        
        switch feedType {
        case .myFeed, .userFeed:
            selectedPost = postCollection?.object(at: UInt(index))
        case .singlePost:
            selectedPost = individualPost
        }
        
        self.editedPost = selectedPost
    }
    
    func getEditPostData() -> TextFeedModel {
        let postModel = createTextFeedModel(post: editedPost)
        return postModel
    }
    
    func getFeedTitle() -> String {
        switch feedType {
        case .myFeed:
            return "My Feed"
        case .userFeed:
            let name = userName ?? "-"
            return ("\(name)'s Feed")
        case .singlePost:
            return "My Post"
        }
    }
    
    // Used in cellForRowAt method to show actual content
    func getFeedItemData(at index: Int) -> FeedItemModel {
        var post: AmityPost?
        
        switch feedType {
        case .myFeed, .userFeed:
            post = postCollection?.object(at: UInt(index))
        case .singlePost:
            post = individualPost
        }
        
        let postModel = createTextFeedModel(post: post)
        return postModel
    }
    
    // Used in cellForRowAt to show reactions data
    func getReactionData(at index: Int) -> String {
        var selectedPost: AmityPost?
        
        switch feedType {
        case .myFeed, .userFeed:
            selectedPost = postCollection?.object(at: UInt(index))
        case .singlePost:
            selectedPost = individualPost
        }
        
        guard let post = selectedPost, let reactions = post.reactions as? [String: Int] else { return "" }
        let data = reactions.map { $1 > 0 ? "\($0): \($1)" : "" }.joined(separator: " ")
        return data
    }
    
    func getCommentsData(at index: Int) -> PostCommentModel? {
        var currentPost: AmityPost?
        
        switch feedType {
        case .myFeed, .userFeed:
            currentPost = postCollection?.object(at: UInt(index))
        case .singlePost:
            currentPost = individualPost
        }
        
        guard let post = currentPost else { return nil }
        return PostCommentModel(post: post)
    }
    
    func getFeedItemViewModels(at index: Int) -> [FeedCellItem] {
        var selectedPost: AmityPost?
        
        switch feedType {
        case .myFeed, .userFeed:
            selectedPost = postCollection?.object(at: UInt(index))
        case .singlePost:
            selectedPost = individualPost
        }
        
        guard let post = selectedPost else { return [] }
        
        var cellItems: [FeedCellItem] = [.header, .content(type: .text)]
        
        // Each post has a property called childrenPosts. This contains an array of AmityPost object.
        // If a post contains files or images, those are present as children posts. So you need
        // to go through that array to determine the post type. In this example i just show 1 image/files
        if let children = post.childrenPosts, children.count > 0 {

            if let firstChild = children.first, firstChild.dataType == "video" {
                // If we found that the first child is "video"
                // We just need to add the first child, since the view model of `.video`
                // already represents all the video children.
                cellItems.append(.content(type: .video))
            } else {
                for aChild in children {
                    switch aChild.dataType {
                    case "image":
                        cellItems.append(.content(type: .image))
                    case "file":
                        cellItems.append(.content(type: .file))
                    case "video":
                        cellItems.append(.content(type: .video))
                    default:
                        cellItems.append(.content(type: .text))
                    }
                }
            }
            
        }
        
        if post.reactionsCount > 0 {
            cellItems.append(.reaction)
        }
        
        cellItems.append(.footer)
        cellItems.append(.comments)
        return cellItems
    }
    
    func getNumberOfFeedItems() -> Int {
        switch feedType {
        case .myFeed, .userFeed:
            let count = Int(postCollection?.count() ?? 0)
            return count
        default:
            return individualPost == nil ? 0 : 1
        }
    }
    
    func getFeedItemHeaderData(at index: Int) -> (title: String, date: String, isDeleted: Bool) {
        var post: AmityPost?
                
        switch feedType {
        case .myFeed, .userFeed:
            post = postCollection?.object(at: UInt(index))
        case .singlePost:
            post = individualPost
        }
        
        let userName = post?.postedUser?.displayName ?? "No Name"
        
        var dateStr = "-"
        if let date = post?.createdAt {
            dateStr = dateFormatter.string(from: date)
        }
        
        return (userName, dateStr, post?.isDeleted ?? false)
    }
    
    func getFeedItemTextData(at index: Int) -> TextFeedModel {
        let post = getPostAtIndex(index: index)
        let postModel = createTextFeedModel(post: post)
        return postModel
    }
    
    func getFeedItemImageData(at index: Int) -> ImageFeedModel {
        // Here i just retrieve the first post present in children post.
        // You might want to go through all children posts to render all images.
        
        let post = getPostAtIndex(index: index)
        
        var imageURL: String = ""
        var imageCount: Int = 0
        
        if let children = post?.childrenPosts, let fileInfo = children.first?.getImageInfo() {
            imageURL = fileInfo.fileURL
            imageCount = children.count
        }
        
        let userName = post?.postedUser?.displayName ?? "No Name"
        
        var dateStr = "-"
        if let date = post?.createdAt {
            dateStr = dateFormatter.string(from: date)
        }
        
        var postModel = ImageFeedModel(fileURL: imageURL, userName: userName, date: dateStr)
        postModel.count = imageCount
        
        return postModel
    }
    
    func getFeedItemFileData(at index: Int) -> FileFeedModel {
        // Here i just retrieve the first post present in children post.
        // You might want to go through all children posts to render all files.
        let post = getPostAtIndex(index: index)
        
        var firstFileURL = ""
        var fileCount = 0
        
        // OR use `getFileInfo` method present in post to return more info about
        // that uploaded file.
        
        if let children = post?.childrenPosts, let fileInfo = children.first?.getFileInfo() {
            
            firstFileURL = fileInfo.fileURL
            fileCount = children.count
        }
        
        let userName = post?.postedUser?.displayName ?? "No Name"
        
        var dateStr = "-"
        if let date = post?.createdAt {
            dateStr = dateFormatter.string(from: date)
        }
        
        var postModel = FileFeedModel(fileURL: firstFileURL, userName: userName, date: dateStr)
        postModel.count = fileCount
        
        return postModel
    }
    
    func getFeedItemVideoData(at index: Int) -> VideoFeedModel {
        // Here i just retrieve the first post present in children post.
        // You might want to go through all children posts to render all videos.
        let post = getPostAtIndex(index: index)
        
        let allVideosInfo: [[NSNumber : AmityVideoData]]
        let thumbnailInfo: AmityImageData?
        
        if let children = post?.childrenPosts {
            allVideosInfo = children.compactMap { post in post.getVideosInfo() }
            thumbnailInfo = children.first?.getVideoThumbnailInfo()
        } else {
            allVideosInfo = []
            thumbnailInfo = nil
        }
        
        let postId = post?.postId ?? "post-id-not-found"
        
        let userName = post?.postedUser?.displayName ?? "No Name"
        var dateStr = "-"
        if let date = post?.createdAt {
            dateStr = dateFormatter.string(from: date)
        }
        
        let model = VideoFeedModel(allVideosInfo: allVideosInfo, thumbnailInfo: thumbnailInfo, postId: postId, userName: userName, date: dateStr)
        
        return model
    }
    
    
}
