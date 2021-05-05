//
//  FeedModels.swift
//  SampleApp
//
//  Created by Nishan Niraula on 4/28/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation

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
    
    init(text: String, userName: String, date: String) {
        self.text = text
        self.userName = userName
        self.date = date
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

protocol FeedItemAction {
    var title: String { get }
    var id: String { get }
}

enum FeedItemDefaultAction: FeedItemAction {
    case edit
    case delete
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
        }
    }
    
    var id: String {
        switch self {
        case .edit:
            return "feed.edit"
        case .delete:
            return "feed.delete"
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
        }
    }
}

enum CommentItemDefaultAction: FeedItemAction {
    case edit
    case delete
    case flag(isFlagged: Bool)
    
    var title: String {
        switch self {
        case .edit:
            return "Edit"
        case .delete:
            return "Delete"
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
        case .flag(let isFlagged):
            return isFlagged ? "comment.unflag" : "comment.flag"
        }
    }
}

struct PostCommentModel {
    private var lastComments: [AmityComment]
    
    init(post: AmityPost) {
        lastComments = post.latestComments
    }
    
    var firstComment: String? {
        return lastComments.count > 0 ? lastComments[0].data?["text"] as? String ?? "" : nil
    }
    
    var secondComment: String? {
        return lastComments.count > 1 ? lastComments[1].data?["text"] as? String ?? "" : nil
    }
}
