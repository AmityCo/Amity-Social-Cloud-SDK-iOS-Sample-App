//
//  UserPostCommentManager.swift
//  SampleApp
//
//  Created by Michael Abadi on 10/06/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//


import Foundation

struct UserPostCommentModel {
    let commentId: String
    let displayName: String
    let text: String
    let date: String
    let reaction: String
}

enum UserPostCommentItem {
    case parent(UserPostCommentModel)
    case child(UserPostCommentModel)
}

class UserPostCommentManager {
    
    let client: AmityClient
    let commentRepository: AmityCommentRepository
    
    var commentCollection: AmityCollection<AmityComment>?
    var commentCollectionToken: AmityNotificationToken?
    
    let reactionRepo: AmityReactionRepository
    
    var editedComment: AmityComment?
    var selectedComment: AmityComment?
    let userId: String?
    let userName: String?
    let postId: String?
    var parentCommentId: String?
    var isReversed = true
    var includeDeleted = false
    
    private var items: [UserPostCommentItem] = []
    
    var editor: AmityCommentEditor? {
        return AmityCommentEditor(client: self.client, comment: self.editedComment!)
    }
    
    var flagger: AmityCommentFlagger?
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter
    }()
    
    init(client: AmityClient, postId: String?, parentCommentId: String? = nil, userId: String?, userName: String? = nil) {
        self.client = client
        self.userId = userId
        self.userName = userName
        self.parentCommentId = parentCommentId
        self.postId = postId
        self.commentRepository = AmityCommentRepository(client: client)
        self.reactionRepo = AmityReactionRepository(client: client)
    }
    
    // MARK:- Comment Observer
    
    // Listen to comment changes. Anytime a comment is created, observer
    // would be notified.
    // Note: Retain that on AmityNotificationToken
    func observeCommentFeedChanges(changeHandler:@escaping ()->()) {
        let orderType: AmityOrderBy = isReversed ? .descending : .ascending
        
        commentCollection = commentRepository.getCommentsWithReferenceId(postId!, referenceType: .post, filterByParentId: true, parentId: parentCommentId, orderBy: orderType, includeDeleted: includeDeleted)
        commentCollectionToken = commentCollection?.observe { [weak self] (collection, _, error) in
            
            Log.add(info: "[COMMENT] Change Observed in Comments \(collection.count())")
            self?.prepareData()
            changeHandler()
        }
    }
    
    func toggleReactionForComment(comment: AmityComment) {
        let reactionName = "like"
        
        if comment.myReactions.contains(reactionName) {
            reactionRepo.removeReaction(reactionName, referenceId: comment.commentId, referenceType: .comment) { (isSuccess, error) in
                
                Log.add(info: "[SampleApp]: Comment reaction removed \(isSuccess), error: \(String(describing: error))")
            }
        } else {
            reactionRepo.addReaction(reactionName, referenceId: comment.commentId, referenceType: .comment) { (isSuccess, error) in
                
                Log.add(info: "[SampleApp]: Comment reaction added \(isSuccess), error: \(String(describing: error)))")
            }
        }
    }
    
    // MARK: CRUD Comment
    
    var newComment: AmityObject<AmityComment>?
    var newCommentToken: AmityNotificationToken?
    
    func createComment(text: String) {
        
        // Observe new comment here.
        newCommentToken?.invalidate()
        
        newComment = commentRepository.createComment(forReferenceId: postId!, referenceType: .post, parentId: parentCommentId, text: text)
        newCommentToken = newComment?.observe { (liveObject, error) in
            
            // Can check .syncState to determine if comment has been successfully created. In case of failure, you can
            // try to show retry alert to user depending upon your use case.
            let syncState = liveObject.object?.syncState
            Log.add(info: "[Comment]: Sync state for new comment: \(String(describing: syncState?.rawValue))")
            Log.add(info: "[Comment]: Data Status: \(liveObject.dataStatus.description)")
            Log.add(info: "[Comment]: Error: \(error)")
        }
    }
    
    func updateComment(text: String, onCompletion: @escaping (_ isSuccess: Bool)->()) {
        guard editedComment != nil else { return }
        
        editor?.editText(text, completion: { (success, _) in
            onCompletion(success)
        })
        
        editedComment = nil
    }
    
    func deleteComment(at index: Int, onCompletion: @escaping (_ isSuccess: Bool)->()) {
        guard let comment = commentCollection?.object(at: UInt(index)) else { return }
        editedComment = comment
        
        commentRepository.delete(editedComment!) { (success, _) in
            onCompletion(success)
        }
        
        editedComment = nil
    }
    
    func toggleReaction(at index: Int) {
        guard let comment = commentCollection?.object(at: UInt(index)) else { return }
        
        toggleReactionForComment(comment: comment)
    }
    
    // MARK: Flagging Comment
    
    func flagComment(at index: Int, onCompletion: @escaping (_ isSuccess: Bool)->()) {
        guard let comment = commentCollection?.object(at: UInt(index)) else { return }
        selectedComment = comment
        
        flagger?.flag(completion: { (success, _) in
            onCompletion(success)
        })
        
        selectedComment = nil
    }
    
    func unflagComment(at index: Int, onCompletion: @escaping (_ isSuccess: Bool)->()) {
        guard let comment = commentCollection?.object(at: UInt(index)) else { return }
        selectedComment = comment
        
        flagger?.unflag(completion: { (success, _) in
            onCompletion(success)
        })
        
        selectedComment = nil
    }
    
    // MARK: Public Helper method
    
    func loadMoreComments() {
        if isReversed {
            guard let hasMoreComments = commentCollection?.hasPrevious, hasMoreComments else { return }
            commentCollection?.previousPage()
        } else {
            guard let hasMoreComments = commentCollection?.hasNext, hasMoreComments else { return }
            commentCollection?.nextPage()
        }
    }
    
    func getNumberOfCommentItems() -> Int {
        return items.count
    }
    
    func getCommentItemHeaderData(at index: Int) -> (title: String, date: String) {
        switch items[index] {
        case .parent(let comment):
            return (comment.displayName, comment.date)
        case .child(let comment):
            return (comment.displayName, comment.date)
        }
    }
    
    func getCommentId(at index: Int) -> String {
        switch items[index] {
        case .parent(let comment):
            return comment.commentId
        case .child(let comment):
            return comment.commentId
        }
    }
    
    func getCommentItem(at index: Int) -> UserPostCommentItem {
        return items[index]
    }
    
    func prepareToFlagComment(at index: Int) {
        let comment = commentCollection?.object(at: UInt(index))
        self.selectedComment = comment
    }
    
    func prepareToEditComment(at index: Int) {
        let comment = commentCollection?.object(at: UInt(index))
        self.editedComment = comment
    }
    
    func getEditCommentData() -> UserPostCommentModel? {
        return editedComment?.asPostCommentModel()
    }
    
    func getReadableDate(date: Date?) -> String {
        if let date = date {
            return dateFormatter.string(from: date)
        } else {
            return ""
        }
    }
    
    func isFlaggedByMe(onCompletion: @escaping (_ isSuccess: Bool)->()){
        flagger = AmityCommentFlagger(client: client, commentId: selectedComment!.commentId)
        flagger?.isFlaggedByMe(completion: { isFlagged in
            onCompletion(isFlagged)
        })
    }
    
    // MARK:- Private Helpers
    
    private func prepareData() {
        guard let commentCollection = commentCollection else { return }
        
        var items: [UserPostCommentItem] = []
        for i in 0..<commentCollection.count() {
            if let comment = commentCollection.object(at: i) {
                // append itself
                items.append(.parent(comment.asPostCommentModel()))
                
                // append comment children
                let childrenComments: [UserPostCommentItem] = comment.childrenComments.map { UserPostCommentItem.child($0.asPostCommentModel()) }
                items += childrenComments
            }
        }
        self.items = items
    }
    
}

private extension AmityComment {
    
    func asPostCommentModel() -> UserPostCommentModel {
        var textData = data?["text"] as? String ?? "-"
        if isDeleted {
            textData = textData + "[Deleted]"
        }
        
        let displayName = user?.displayName ?? "No Name"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        let dateStr = formatter.string(from: createdAt)
        
        if let raction = reactions as? [String: Int] {
            let formattedReaction = raction.map { $1 > 0 ? "\($0): \($1)" : "" }.joined(separator: " ")
            return UserPostCommentModel(commentId: commentId, displayName: displayName, text: textData, date: dateStr, reaction: formattedReaction)
        } else {
            return UserPostCommentModel(commentId: commentId, displayName: displayName, text: textData, date: dateStr, reaction: "")
        }
    }
    
}
