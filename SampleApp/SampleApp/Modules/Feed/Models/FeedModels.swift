//
//  FeedModels.swift
//  SampleApp
//
//  Created by Nishan Niraula on 4/28/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit
import AmitySDK

enum FeedCellItem {
    case header
    case footer
    case content(type: FeedItemType)
    case reaction
    case comments
    
    var height: CGFloat {
        switch self {
        case .header:
            return 70
        case .content, .comments:
                return UITableView.automaticDimension
        case .reaction:
            return 40
        case .footer:
            return 50
        }
    }
}

enum FeedItemType {
    case text
    case image
    case file
    case video
    case liveStream
    case poll
}

protocol FeedItemModel {
    var type: FeedItemType { get }
    var userName: String { get set }
    var date: String { get set }
}

// Sample models. Will change later when integrating with sdk
struct TextFeedModel: FeedItemModel {
    var type: FeedItemType = .text
    var text: String
    var userName: String
    var date: String
    var metadata: [String: Any]?
    
    init(text: String, userName: String, date: String, metadata: [String: Any]?) {
        self.text = text
        self.userName = userName
        self.date = date
        self.metadata = metadata
    }
}

struct ImageFeedModel: FeedItemModel {
    var type: FeedItemType = .image
    var count: Int = 0
    var fileURL: String
    var userName: String
    var date: String
    
    init(fileURL: String, userName: String, date: String) {
        self.fileURL = fileURL
        self.userName = userName
        self.date = date
    }
}

struct FileFeedModel: FeedItemModel {
    var type: FeedItemType = .file
    var count: Int = 0
    var fileURL: String
    var userName: String
    var date: String
    
    init(fileURL: String, userName: String, date: String) {
        self.fileURL = fileURL
        self.userName = userName
        self.date = date
    }
}

struct VideoFeedModel: FeedItemModel {
    let type: FeedItemType = .video
    var allVideosInfo: Array<[NSNumber : AmityVideoData]> = []
    var thumbnailInfo: AmityImageData?
    var postId: String
    var userName: String
    var date: String
}

class PollFeedModel: FeedItemModel {
    var type: FeedItemType = .poll
    var userName: String
    var date: String
    var id: String
    var text: String = ""
    var dataType: String = "text"
    var answers: [PollFeedAnswerModel] = []
    var isMultipleVoted: Bool = false
    var status: String = "open"
    var isClosed: Bool = false
    var isVoted: Bool = false
    var closedIn: Int = 0
    var voteCount: Int = 0
    
    init(userName: String, date: String, id: String) {
        self.userName = userName
        self.date = date
        self.id = id
    }
    
    class PollFeedAnswerModel {
        var id: String
        var dataType: String
        var text: String
        var isVotedByUser: Bool
        var voteCount: Int
        var isSelected: Bool = false
        
        init(id: String, dataType: String, text: String, isVotedByUser: Bool, voteCount: Int) {
            self.id = id
            self.dataType = dataType
            self.text = text
            self.isVotedByUser = isVotedByUser
            self.voteCount = voteCount
        }
    }
}

protocol FeedItemAction {
    var title: String { get }
    var id: String { get }
}

enum FeedItemDefaultAction: FeedItemAction {
    
    case edit
    case delete
    case hardDelete
    case like
    case comment
    case love
    case sortLastCreated
    case sortFirstCreated
    case viewPost
    case flag
    case unflag
    case shouldIncludeDeleted
    case shouldNotIncludeDeleted
    case viewCommunityMembership
    case copyPostId
    case publishedAndSortLastCreated
    case publishedAndSortFirstCreated
    case reviewingAndSortLastCreated
    case reviewingAndSortFirstCreated
    case approve
    case decline
    case realTimeEvent
    
    var title: String {
        switch self {
        case .edit:
            return "Edit"
        case .delete:
            return "Delete"
        case .like:
            return "Like"
        case .comment:
            return "Comment"
        case .love:
            return "Love"
        case .sortLastCreated:
            return "Last Created"
        case .sortFirstCreated:
            return "First Created"
        case .viewPost:
            return "View Post"
        case .flag:
            return "Flag Post"
        case .unflag:
            return "UnFlag Post"
        case .shouldIncludeDeleted:
            return "Include Deleted: True"
        case .shouldNotIncludeDeleted:
            return "Include Deleted: False"
        case .viewCommunityMembership:
            return "View Community Membership"
        case .copyPostId:
            return "Copy Post Id"
        case .publishedAndSortFirstCreated:
            return "Published | First Created"
        case .publishedAndSortLastCreated:
            return "Published | Last Created"
        case .reviewingAndSortFirstCreated:
            return "Reviewing | First Created"
        case .reviewingAndSortLastCreated:
            return "Reviewing | Last Created"
        case .approve:
            return "Approve"
        case .decline:
            return "Decline"
        case .hardDelete:
            return "Hard Delete"
        case .realTimeEvent:
            return "Real Time Event"
        }
    }
    
    var id: String {
        switch self {
        case .edit:
            return "feed.edit"
        case .delete:
            return "feed.delete"
        case .hardDelete:
            return "feed.hardDelete"
        case .like:
            return "feed.like"
        case .comment:
            return "feed.comment"
        case .love:
            return "feed.love"
        case .sortLastCreated:
            return "feed.sort.last.created"
        case .sortFirstCreated:
            return "feed.sort.first.created"
        case .viewPost:
            return "feed.view"
        case .flag:
            return "feed.flag"
        case .unflag:
            return "feed.unflag"
        case .shouldIncludeDeleted:
            return "feed.include.deleted"
        case .shouldNotIncludeDeleted:
            return "feed.not.include.deleted"
        case .viewCommunityMembership:
            return "feed.view.community.membership"
        case .copyPostId:
            return "feed.copy.post.id"
        case .publishedAndSortFirstCreated:
            return "feed.post.published.first.create"
        case .publishedAndSortLastCreated:
            return "feed.post.published.last.create"
        case .reviewingAndSortFirstCreated:
            return "feed.post.reviewing.first.create"
        case .reviewingAndSortLastCreated:
            return "feed.post.reviewing.last.create"
        case .approve:
            return "feed.post.approve"
        case .decline:
            return "feed.post.decline"
        case .realTimeEvent:
            return "feed.real.time.event"
        }
    }
}

enum CommentItemDefaultAction: FeedItemAction {
    
    case edit
    case delete
    case hardDelete
    case flag(isFlagged: Bool)
    
    var title: String {
        switch self {
        case .edit:
            return "Edit"
        case .delete:
            return "Delete"
        case .hardDelete:
            return "Hard Delete"
        case .flag(let isFlagged):
            return isFlagged ? "Unflag" : "Flag"
        }
    }
    
    var id: String {
        switch self {
        case .edit:
            return "comment.edit"
        case .delete:
            return "comment.delete"
        case .hardDelete:
            return "comment.hardDelete"
        case .flag(let isFlagged):
            return isFlagged ? "comment.unflag" : "comment.flag"
        }
    }
}

class PostCommentModel {
    private var lastComments: [AmityComment]
    
    init(post: AmityPost) {
        lastComments = post.latestComments
    }
    
    var firstComment: AmityComment? {
        return lastComments.count > 0 ? lastComments[0] : nil
    }
    
    var secondComment: AmityComment? {
        return lastComments.count > 1 ? lastComments[1] : nil
    }
}
