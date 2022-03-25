//
//  SDKModel+Extension.swift
//  SampleApp
//
//  Created by Nishan Niraula on 11/24/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import Foundation

extension AmityPost {
    
    var modelDescription: String {
        return """
            Post:
            
            Id: \(self.postId)
            Data Type: \(self.dataType)
            Data: \(String(describing: self.data))
            Child Posts Count: \(self.childrenPosts?.count ?? 0)
            Reactions Count: \(self.reactionsCount)
            Reactions: \(String(describing: self.reactions))
            Flag Count: \(self.flagCount)
            Comments Count: \(self.commentsCount)
            Target Community: \(self.targetCommunity?.communityId ?? "")
            Deleted Status: \(self.isDeleted)
            """
    }
}

extension AmityUser {
    
    var modelDescription: String {
        
        let userRoles = self.roles as? [String] ?? []
        
        return """
            User:
            
            Id: \(self.userId)
            Display Name: \(self.displayName ?? "-")
            User Description: \(self.userDescription)
            Roles: \(userRoles.joined(separator: ","))
            Flag Count: \(self.flagCount)
            Avatar FileId: \(self.avatarFileId ?? "")
            Avatar Custom URL: \(self.avatarCustomUrl ?? "")
            """
    }
}

extension AmityCommunity {
    
    var modelDescription: String {
        return """
            Community:
            
            Id: \(self.communityId)
            Display Name: \(self.displayName)
            Description: \(self.communityDescription)
            Post Count: \(self.postsCount)
            Members Count: \(self.membersCount)
            Public Status: \(self.isPublic)
            Joined Status: \(self.isJoined)
            Deleted Status: \(self.isDeleted)
            Post Review Enabled: \(self.isPostReviewEnabled)
            """
    }
}

extension AmityComment {
    
    var modelDescription: String {
        return """
            Comment:
            
            Id: \(self.commentId)
            Data: \(String(describing: self.data))
            ReferenceId: \(self.referenceId)
            ReferenceType: \(self.referenceType.description)
            UserId: \(self.userId)
            Data Type: \(self.dataType.description)
            Reactions: \(String(describing: self.reactions))
            My Reactions: \(self.myReactions)
            Flag Count: \(self.flagCount)
            Replies Count: \(self.childrenNumber)
            Deleted Status: \(self.isDeleted)
            Sync State: \(self.syncState.description)
            """
    }
}

extension AmityCommentReferenceType {
    
    var description: String {
        switch self {
        case .content:
            return "Content"
        case .post:
            return "Post"
        @unknown default:
            return ""
        }
    }
}

extension AmityDataType {
    
    var description: String {
        switch self {
        case .text:
            return "Text"
        default:
            return ""
        }
    }
}
