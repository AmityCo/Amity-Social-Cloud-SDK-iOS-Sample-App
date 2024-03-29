//
//  UserPostsFeedViewController.swift
//  SampleApp
//
//  Created by Nishan Niraula on 4/27/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit
import AVKit
import AmitySDK
import SwiftUI

struct NavigationControllerKey: EnvironmentKey {
    static let defaultValue: UINavigationController? = nil
}

extension EnvironmentValues {
    var navigationController: NavigationControllerKey.Value {
        get {
            return self[NavigationControllerKey.self]
        }
        set {
            self[NavigationControllerKey.self] = newValue
        }
    }
}

// NOTE
//
// This class sets up the UI part for the Current User Feed. It shows the posts for
// logged in user. Look into `UserPostsFeedManager` for actual interaction with SDK.
class UserPostsFeedViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sortInfoLabel: UILabel!
    @IBOutlet weak var userInfoContainerView: UIView!
    @IBOutlet weak var userAvatarView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userIdLabel: UILabel!
    
    var feedManager: UserPostsFeedManager!
    var userName: String?
    var isGlobalFeed: Bool {
        switch feedManager.feedType {
            
        case .globalFeed, .customPostRankingGlobalFeed:
            return true
        case .myFeed, .userFeed, .singlePost, .community:
            return false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupPostsObserver()
        feedManager.sortCommunityHandler = { [weak self] in
            // The post collection has changed via sort function, currently feedManager won't re-observe automatically.
            // So here we setup and re-observe new post collection manually.
            self?.setupPostsObserver()
        }
    }
    
    private func setupPostsObserver() {
        feedManager.observePostsFeedChanges { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    func setupViews() {
        switch feedManager.feedType {
        case .userFeed:
            userAvatarView.layer.cornerRadius = 25
            userAvatarView.layer.masksToBounds = true
            userAvatarView.image = UIImage(named: "feed_profile")?.withRenderingMode(.alwaysOriginal)
            
            let feedName = feedManager.getFeedTitle()
            userNameLabel.text = feedName
            userIdLabel.text = feedManager.userId
        case .community:
            self.title = feedManager.getFeedTitle()
            userInfoContainerView.removeFromSuperview()
        default:
            userInfoContainerView.removeFromSuperview()
        }

        let deletedFilterButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(onDeletedPostFilterButtonTap))
        
        if !isGlobalFeed {
            let sortButton = UIBarButtonItem(image: UIImage(named: "feed_sort"), style: .plain, target: self, action: #selector(onSortButtonTap))
            let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAddButtonTap))
            self.navigationItem.rightBarButtonItems = [addButton, sortButton, deletedFilterButton]
        } else {
            self.navigationItem.rightBarButtonItems = [deletedFilterButton]
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.reloadData()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReactionCell")
        
        sortInfoLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        updateSortInfoLabel(option: isGlobalFeed ? "-" : "Last Created")
    }
    
    func updateSortInfoLabel(option: String) {
        sortInfoLabel.text = "Sorted By: \(option)"
    }
    
    @objc func onAddButtonTap() {
        displayNewPostsScreen(isEditMode: false)
    }
    
    @objc func onSortButtonTap() {
        if feedManager.community != nil {
            let actions: [FeedItemDefaultAction] = [.publishedAndSortFirstCreated, .publishedAndSortLastCreated, .reviewingAndSortFirstCreated, .reviewingAndSortLastCreated]
            displayMoreActions(title: "Sort the feed by", actions: actions, at: -1)
        } else {
            let actions: [FeedItemDefaultAction] = [.sortFirstCreated, .sortLastCreated]
            displayMoreActions(title: "Sort the feed by", actions: actions, at: -1)
        }
        
    }
    
    @objc func onDeletedPostFilterButtonTap() {
        let actions: [FeedItemDefaultAction] = [.shouldIncludeDeleted, .shouldNotIncludeDeleted]
        displayMoreActions(title: "Include Deleted Posts?", actions: actions, at: -1)
        
    }
    
    func displayNewPostsScreen(isEditMode: Bool) {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: NewUserPostsViewController.identifier) as! NewUserPostsViewController
        controller.delegate = self
        controller.currentMode = isEditMode ? .edit() : .create()
        controller.feedManager = feedManager
        
        if let community = feedManager.community {
            controller.communityId = community.communityId
            controller.isCommunityPost = true
        }
        
        if #available(iOS 13.0, *) {
            // Prevents screen to dismiss when swiping down on ios 13
            controller.isModalInPresentation = true
        }
        
        self.present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
    }
    
    func showAlert(alertMessage: String) {
        
        let alert = UIAlertController(title: "", message: alertMessage, preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func presentChooseVideoItemDialogue(data: VideoFeedModel) {
        let alertController = UIAlertController(title: "Watch Video", message: nil, preferredStyle: .actionSheet)
        for (index, videosInfo) in data.allVideosInfo.enumerated() {
            let pick = UIAlertAction(title: "\(index + 1)", style: .default) { [weak self] action in
                self?.presentChooseVideoQualityDialogue(videosInfo: videosInfo)
            }
            alertController.addAction(pick)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    private func presentChooseVideoQualityDialogue(videosInfo: [NSNumber : AmityVideoData]) {
        let alertController = UIAlertController(title: "Choose Quality", message: nil, preferredStyle: .actionSheet)
        for quality in AmityVideoDataQuality.allCases {
            if let videoData = videosInfo[quality.rawValue as NSNumber],
               let url = URL(string: videoData.fileURL) {
                let pick = UIAlertAction(title: "\(quality.stringValue())", style: .default) { [weak self] action in
                    self?.playVideo(url: url)
                }
                alertController.addAction(pick)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    private func playVideo(url: URL) {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        present(controller, animated: true) {
            player.play()
        }
    }
    
    // Support Pagination
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let frameHeight = scrollView.frame.size.height
        let contentOffset = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        let distanceFromBottom = contentHeight - contentOffset
        if distanceFromBottom < frameHeight {
            feedManager.loadMorePosts()
        }
    }
}

extension UserPostsFeedViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return feedManager.getNumberOfFeedItems()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let feedItemViewModel = feedManager.getFeedItemViewModels(at: section)
        return feedItemViewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellItems = feedManager.getFeedItemViewModels(at: indexPath.section)
        let currentCellItem = cellItems[indexPath.row]
        
        switch currentCellItem {
        case .header:
            
            let data = feedManager.getFeedItemHeaderData(at: indexPath.section)
            
            // create actions list based on business logic.
            var actions: [FeedItemDefaultAction] = []
            actions.append(.comment)
            if !data.isPoll {
                actions.append(.edit)
            }
            actions.append(contentsOf: [
                .hardDelete,
                .delete,
                .viewPost,
                .flag,
                .unflag,
                .viewCommunityMembership,
                .copyPostId
            ])
            if self.feedManager.community != nil {
                actions.append(contentsOf: [.approve, .decline])
            }
            actions.append(.realTimeEvent)
            
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedPostHeaderCell.identifier) as! FeedPostHeaderCell
            cell.configure(title: data.title, date: data.date, isDeleted: data.isDeleted)
            cell.moreButtonAction = { [weak self] in
                self?.displayMoreActions(title: "What would you like to do?", actions: actions, at: indexPath.section)
            }
            
            let post = feedManager.getPostAtIndex(index: indexPath.section)
            feedManager.flagger.isPostFlaggedByMe(post: post) { (isFlagged) in
                cell.flagInfo.text = isFlagged ? "Flagged" : ""
            }
            
            return cell
            
        case .content(let type):
            
            switch type {
            case .text:
                let cell = tableView.dequeueReusableCell(withIdentifier: FeedPostMultilineLabelCell.identifier) as! FeedPostMultilineLabelCell
                
                let data = feedManager.getFeedItemTextData(at: indexPath.section)
                if let post = feedManager.getPostAtIndex(index: indexPath.section), let mentionees = post.mentionees, let metadata = post.metadata {
                    cell.feedTextLabel.attributedText = AmityMentionManager.getAttributedString(text: data.text, withMetadata: metadata, mentionees: mentionees)
                } else {
                    cell.feedTextLabel.text = data.text
                }
                return cell
                
            case .liveStream:
                
                let cell = tableView.dequeueReusableCell(withIdentifier: FeedPostMultilineLabelCell.identifier) as! FeedPostMultilineLabelCell
                
                let data = feedManager.getFeedItemLiveStreamData(at: indexPath.section)
                cell.feedTextLabel.text = data.text
                
                return cell
                
            case .file:
                let cell = tableView.dequeueReusableCell(withIdentifier: FeedPostImageCell.identifier) as! FeedPostImageCell
                
                let data = feedManager.getFeedItemFileData(at: indexPath.section)
                cell.imageCountLabel.text = "\(data.count) Files"
                
                Log.add(info: "Extracted File id: \(data.fileURL)")
                
                // Download file Here...
                
                return cell
                
            case .video:
                
                let cell = tableView.dequeueReusableCell(withIdentifier: FeedPostImageCell.identifier) as! FeedPostImageCell
                
                let data = feedManager.getFeedItemVideoData(at: indexPath.section)
                
                cell.videoFeedModel = data
                cell.imageCountLabel.text = "\(data.allVideosInfo.count) Videos"
                cell.delegate = self
                
                if let thumbnailFileUrl = data.thumbnailInfo?.fileURL {
                    feedManager.downloadImage(fileUrl: thumbnailFileUrl) { image in
                        guard
                            let videoInfo = cell.videoFeedModel,
                            videoInfo.postId == data.postId else {
                            // Cell has been dequeue already, no need to set the image.
                            return
                        }
                        cell.imageView1.image = image
                    }
                }
                
                Log.add(info: "Extracted videos data at post id: \(data.postId)")
                
                return cell
                
            case .image:
                let cell = tableView.dequeueReusableCell(withIdentifier: FeedPostImageCell.identifier) as! FeedPostImageCell
                
                let data = feedManager.getFeedItemImageData(at: indexPath.section)
                cell.imageCountLabel.text = "\(data.count) images"
                
                //let imageId = data.imageInfo.first?["fileId"] as? String ?? ""
                Log.add(info: "Extracted image id: \(data.fileURL)")
                
                feedManager.downloadImage(fileUrl: data.fileURL) { image in
                    cell.imageView1.image = image
                }
                
                return cell
            case .poll:
                let cell = tableView.dequeueReusableCell(withIdentifier: FeedPostPollCell.identifier, for: indexPath) as! FeedPostPollCell
                let data = feedManager.getFeedItemPollData(at: indexPath.section)
                cell.delegate = self
                cell.display(model: data)
                
                return cell
            }
            
        case .reaction:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReactionCell")!
            cell.backgroundColor = .systemGroupedBackground
            cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
            
            let data = feedManager.getReactionData(at: indexPath.section)
            cell.textLabel?.text = data
            
            return cell
            
        case .footer:
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedPostFooterCell.identifier) as! FeedPostFooterCell
            
            cell.likeButtonAction = { [weak self] in
                self?.executeFeedAction(action: FeedItemDefaultAction.like, at: indexPath.section)
            }
            
            cell.loveButtonAction = { [weak self] in
                self?.executeFeedAction(action: FeedItemDefaultAction.love, at: indexPath.section)
            }
            
            return cell
        case .comments:
            let cell = tableView.dequeueReusableCell(withIdentifier: FeedPostCommentsCell.identifier) as! FeedPostCommentsCell
            
            if let comments = feedManager.getCommentsData(at: indexPath.section) {
                cell.setData(model: comments)
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellItems = feedManager.getFeedItemViewModels(at: indexPath.section)
        let currentCellItem = cellItems[indexPath.row]
        
        switch currentCellItem {
        case .reaction:
            let controller = self.storyboard?.instantiateViewController(withIdentifier: UserPostReactionsViewController.identifier) as! UserPostReactionsViewController
            
            let post = feedManager.getPostAtIndex(index: indexPath.section)
            controller.feedManager = feedManager
            controller.post = post
            
            self.navigationController?.pushViewController(controller, animated: true)
            
        default:
            
            guard let post = feedManager.getPostAtIndex(index: indexPath.section) else { return }
            
            Log.add(info: "\n--- Post Info ---\n")
            Log.add(info: "Id: \(post.postId)")
            Log.add(info: "Parent Post Id: \(String(describing: post.parentPostId))")
            Log.add(info: "Children Count: \(post.childrenPosts?.count ?? 0)")
            
            if let childrenPost = post.childrenPosts, childrenPost.count > 0 {
                for ch in childrenPost {
                    Log.add(info: "> childrenPosts: Data Type \(ch.dataType)")
                    Log.add(info: "> childrenPosts: Post id \(ch.postId)")
                    Log.add(info: "> childrenPosts: Parent post id \(String(describing: ch.parentPostId))")
                }
            }
            Log.add(info: "Comments Count: \(post.commentsCount)")
            Log.add(info: "Getting latest comments...")
            
            let comments = post.latestComments
            Log.add(info: "\(comments.count) comments retrieved")
            for comment in comments {
                Log.add(info: "> getLatestComment: Comment Id: \(comment.commentId)")
                Log.add(info: "> getLatestComment: Data: \(String(describing: comment.data))")
            }
            
            Log.add(info: "File Info: \(String(describing: post.getFileInfo()))")
            Log.add(info: "Image Info: \(String(describing: post.getImageInfo()))")
            Log.add(info: "Target Id: \(post.targetId)")
            Log.add(info: "Community Info: \(String(describing: post.targetCommunity?.communityId))")
            Log.add(info: "Community Category Ids: \(String(describing: post.targetCommunity?.categoryIds))")
            Log.add(info: "Mapped Category count: \(String(describing: post.targetCommunity?.categories.count))")
            Log.add(info: "--------------")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellItems = feedManager.getFeedItemViewModels(at: indexPath.section)
        guard cellItems.count > indexPath.row else { return UITableView.automaticDimension }
        let currentCellItem = cellItems[indexPath.row]
        switch currentCellItem {
        case .content(let type):
            switch type {
            case .poll:
                let data = feedManager.getFeedItemPollData(at: indexPath.section)
                let labelCount: CGFloat = 7
                let spacer: CGFloat = 8
                let heightLabel: CGFloat = 20
                let heightButton: CGFloat = 50
                return (labelCount * heightLabel) + ((labelCount + 2) * spacer) + (heightButton * 2) + CGFloat(58 * data.answers.count)
            default:
                return currentCellItem.height
            }
        default:
            return currentCellItem.height
        }
    }
}

// MARK:- Feed Actions

extension UserPostsFeedViewController {
    
    func displayMoreActions(title: String, actions: [FeedItemAction], at index: Int) {
        let alertController = UIAlertController(title: "", message: title, preferredStyle: .actionSheet)
        
        for action in actions {
            let sheetAction = UIAlertAction(title: action.title, style: .default) { [weak self] _ in
                self?.executeFeedAction(action: action, at: index)
            }
            alertController.addAction(sheetAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func executeFeedAction(action: FeedItemAction, at index: Int) {
        
        switch action.id {
        case FeedItemDefaultAction.edit.id:
            
            feedManager.prepareToEditPost(at: index)
            displayNewPostsScreen(isEditMode: true)
            
        case FeedItemDefaultAction.delete.id:
            feedManager.deletePost(at: index, hardDelete: false) { [weak self] (isSuccess) in
                let alertMessage = isSuccess ? "Post successfully deleted" : "Error while deleting post"
                self?.showAlert(alertMessage: alertMessage)
            }
            
        case FeedItemDefaultAction.hardDelete.id:
            feedManager.deletePost(at: index, hardDelete: true) { [weak self] (isSuccess) in
                let alertMessage = isSuccess ? "Post successfully deleted" : "Error while deleting post"
                self?.showAlert(alertMessage: alertMessage)
            }
            
        case FeedItemDefaultAction.like.id:
            feedManager.addReactionToPost(at: index, reaction: "like")
            
        case FeedItemDefaultAction.love.id:
            feedManager.addReactionToPost(at: index, reaction: "love")
            
        case FeedItemDefaultAction.comment.id:
            let controller = self.storyboard?.instantiateViewController(withIdentifier: UserPostCommentsViewController.identifier) as! UserPostCommentsViewController
            
            let post = feedManager.getPostAtIndex(index: index)
            controller.community = feedManager.community
            controller.commentManager = UserPostCommentManager(client: feedManager.client, postId: post?.postId, parentCommentId: nil, userId: feedManager.client.currentUserId, userName: feedManager.client.currentUser?.object?.displayName, communityId: nil)
            
            navigationController?.pushViewController(controller, animated: true)
        case FeedItemDefaultAction.sortFirstCreated.id:
            feedManager.sortCurrentFeed(option: .firstCreated)
            updateSortInfoLabel(option: "First Created")
        case FeedItemDefaultAction.sortLastCreated.id:
            feedManager.sortCurrentFeed(option: .lastCreated)
            updateSortInfoLabel(option: "Last Created")
        case FeedItemDefaultAction.publishedAndSortFirstCreated.id:
            feedManager.sortCurrentFeedCommunity(option: .publishedAndSortFirstCreated)
            updateSortInfoLabel(option: FeedItemDefaultAction.publishedAndSortFirstCreated.title)
        case FeedItemDefaultAction.publishedAndSortLastCreated.id:
            feedManager.sortCurrentFeedCommunity(option: .publishedAndSortLastCreated)
            updateSortInfoLabel(option: FeedItemDefaultAction.publishedAndSortLastCreated.title)
        case FeedItemDefaultAction.reviewingAndSortFirstCreated.id:
            feedManager.sortCurrentFeedCommunity(option: .reviewingAndSortFirstCreated)
            updateSortInfoLabel(option: FeedItemDefaultAction.reviewingAndSortFirstCreated.title)
        case FeedItemDefaultAction.reviewingAndSortLastCreated.id:
            feedManager.sortCurrentFeedCommunity(option: .reviewingAndSortLastCreated)
            updateSortInfoLabel(option: FeedItemDefaultAction.reviewingAndSortLastCreated.title)
        case FeedItemDefaultAction.viewPost.id:
            let post = feedManager.getPostAtIndex(index: index)
            displayIndividualPost(post: post)
            
        case FeedItemDefaultAction.flag.id:
            let post = feedManager.getPostAtIndex(index: index)
            feedManager.flagger.flagPost(post: post, completion: { [weak self] isSuccess in
                
                let message = isSuccess ? "Successfully Flagged!" : "This post was already flagged"
                self?.showAlert(alertMessage: message)
            })
            
        case FeedItemDefaultAction.unflag.id:
            let post = feedManager.getPostAtIndex(index: index)
            feedManager.flagger.unflagPost(post: post, completion: { [weak self] isSuccess in
                
                let message = isSuccess ? "Successfully UnFlagged!" : "This post was already unflagged"
                self?.showAlert(alertMessage: message)
            })
            
        case FeedItemDefaultAction.shouldIncludeDeleted.id:
            feedManager.includeDeletedPosts = true
            if feedManager.community != nil {
                feedManager.sortCurrentFeedCommunity(option: feedManager.feedSortCommunityOption)
            } else {
                feedManager.sortCurrentFeed(option: feedManager.feedSortOption)
            }
            
            
        case FeedItemDefaultAction.shouldNotIncludeDeleted.id:
            feedManager.includeDeletedPosts = false
            if feedManager.community != nil {
                feedManager.sortCurrentFeedCommunity(option: feedManager.feedSortCommunityOption)
            } else {
                feedManager.sortCurrentFeed(option: feedManager.feedSortOption)
            }
            
            
        case FeedItemDefaultAction.viewCommunityMembership.id:
            let membershipData = feedManager.viewCommunityMembership(index: index)
            self.showAlert(alertMessage: membershipData)
            
        case FeedItemDefaultAction.copyPostId.id:
            let postId = feedManager.getPostAtIndex(index: index)?.postId
            UIPasteboard.general.string = postId
        case FeedItemDefaultAction.approve.id:
            let post = feedManager.getPostAtIndex(index: index)
            feedManager.approve(post: post) { [weak self] message in
                self?.showAlert(alertMessage: message)
                self?.tableView.reloadData()
            }
        case FeedItemDefaultAction.decline.id:
            let post = feedManager.getPostAtIndex(index: index)
            feedManager.decline(post: post) { [weak self] message in
                self?.showAlert(alertMessage: message)
                self?.tableView.reloadData()
            }
            
        case FeedItemDefaultAction.realTimeEvent.id:
            guard let post = feedManager.getPostAtIndex(index: index) else { return }
            
            let controller = PostRealTimeEventController()
            let manager = PostRealTimeEventManager(post: post, isObserveMode: false)
            controller.manager = manager
            
            self.navigationController?.pushViewController(controller, animated: true)
        default:
            fatalError("Implementation not found for action \(action.title)")
        }
    }
    
    func displayIndividualPost(post: AmityPost?) {
        
        let newFeedManager = UserPostsFeedManager(client: feedManager.client, userId: feedManager.userId, userName: feedManager.userName)
        newFeedManager.feedType = .singlePost
        newFeedManager.postId = post?.postId
        
        let postsFeedStoryboard = UIStoryboard(name: "Feed", bundle: nil)
        let postsFeedController = postsFeedStoryboard.instantiateViewController(withIdentifier: UserPostsFeedViewController.identifier) as! UserPostsFeedViewController
        postsFeedController.feedManager = newFeedManager
        
        self.navigationController?.pushViewController(postsFeedController, animated: true)
    }
}


extension UserPostsFeedViewController: FeedPostImageCellDelegate {
    
    
    func feedPostImageCellDidTapImage(_ cell: FeedPostImageCell, videoFeedModel: VideoFeedModel) {
        presentChooseVideoItemDialogue(data: videoFeedModel)
    }
    
}

extension UserPostsFeedViewController: NewUserPostsViewControllerDelegate {
    func newUserPostsViewControllerDidUpdateComment() {
    }
    
    func newUserPostsViewControllerDidCreateNewPost(_ controller: NewUserPostsViewController) {
        feedManager.observePostsFeedChanges { [weak self] in
            self?.setupPostsObserver()
        }
    }
}
    
extension UserPostsFeedViewController: FeedPostPollCellDelegate {
    
    func feedPostPollCellDidTapVotePoll(model: PollFeedModel, answerIds: [String]) {
        feedManager.votePoll(withPollid: model.id, answerIds: answerIds) { [weak self] isSuccess in
            let alertMessage = isSuccess ? "Poll successfully Voted" : "Error while voting poll"
            self?.showAlert(alertMessage: alertMessage)
        }
    }
    
    func feedPostPollCellDidTapClosePoll(model: PollFeedModel) {
        feedManager.closedPoll(withPollId: model.id) { [weak self] isSuccess in
            let alertMessage = isSuccess ? "Poll successfully closed" : "Error while closing poll"
            self?.showAlert(alertMessage: alertMessage)
        }
    }
}
