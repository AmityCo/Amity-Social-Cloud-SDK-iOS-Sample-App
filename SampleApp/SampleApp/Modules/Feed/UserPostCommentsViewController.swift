//
//  UserPostCommentsViewController.swift
//  SampleApp
//
//  Created by Michael Abadi on 10/06/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit
import AmitySDK

class UserPostCommentsViewController: UIViewController {
private let reuseIdentifier = "SampleAppTableViewCell"
    
    var client: AmityClient?
    var commentManager: UserPostCommentManager!
    var community: CommunityListModel?
    
    @IBOutlet weak var commentsTableView: UITableView!
    @IBOutlet weak var inputContainer: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var replyContainerView: UIView!
    @IBOutlet weak var replyLabel: UILabel!
    @IBOutlet weak var inputContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var membersTableView: UITableView!
    @IBOutlet private weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    private var mentionManager: AmityMentionManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queryOptionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(onQueryOptionButtonTap))
        self.navigationItem.rightBarButtonItem = queryOptionButton
        
        textView.delegate = self
        setPlaceholder()
        
        commentsTableView.dataSource = self
        commentsTableView.delegate = self
        commentsTableView.separatorStyle = .singleLine
        commentsTableView.reloadData()
        replyContainerView.isHidden = true
        
        membersTableView.delegate = self
        membersTableView.dataSource = self
        
        let nib = UINib(nibName: "SampleAppTableViewCell", bundle: nil)
        membersTableView?.register(nib, forCellReuseIdentifier: reuseIdentifier)
        
        membersTableView?.tableFooterView = UIView()
        
        hideMentionsTableView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mentionManager?.delegate = nil
    }
    
    private func hideMentionsTableView() {
        tableViewHeightConstraint.constant = 0
        membersTableView?.isHidden = true
    }
    
    @objc func onQueryOptionButtonTap() {
        
        let alertController = UIAlertController(title: "Choose Query Option", message: "", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Include Deleted Comments", style: .default, handler: { [weak self] _ in
            self?.commentManager.includeDeleted = true
            self?.fetchComments()
        }))
        alertController.addAction(UIAlertAction(title: "Don't Include Deleted Comments", style: .default, handler: { [weak self] _ in
            self?.commentManager.includeDeleted = false
            self?.fetchComments()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        KeyboardService.shared.delegate = self
        fetchComments()
        
        setupMentionManager()
    }
    
    private func setupMentionManager() {
        var mentionType = AmityMentionManagerType.comment(communityId: nil)
        if let community = community, !community.isPublic {
            mentionType = .comment(communityId: community.communityId)
        }
        mentionManager = AmityMentionManager(withType: mentionType)
        mentionManager?.delegate = self
    }
    
    func fetchComments() {
        commentManager.observeCommentFeedChanges { [weak self] in
           self?.commentsTableView.reloadData()
        }
    }
    
    @IBAction func handleSendButton(_ sender: Any) {
        sendTextComment()
    }
    
    @IBAction func replyDismissButton(_ sender: Any) {
        commentManager.parentCommentId = nil
        replyContainerView.isHidden = true
    }
    
    private func sendTextComment() {
        guard let text: String = textView.text, !text.isEmpty else { return }

        if text.count > 50000 {
            showAlertForMaximumCharacters()
            return
        }
        
        if let metadata = mentionManager?.getMetadata(), let mentionees = mentionManager?.getMentionees() {
            commentManager.createComment(text: text, metadata: metadata, mentionees: mentionees)
        } else {
            commentManager.createComment(text: text)
        }
        
        mentionManager?.resetState()
        textView.text = ""
        textView.attributedText = nil
        textView.textColor = .black
        textView.resignFirstResponder()
    }
    
    private func setPlaceholder() {
        textView.text = "Enter message here"
        textView.textColor = UIColor.lightGray
    }
    
    private func displayMoreActions(title: String, actions: [FeedItemAction], at index: Int) {
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
    
    private func executeFeedAction(action: FeedItemAction, at index: Int) {
        
        switch action.id {
        case CommentItemDefaultAction.edit.id:
            commentManager.prepareToEditComment(at: index)
            displayNewPostsScreen(isEditMode: true)
            
        case CommentItemDefaultAction.delete.id:
            commentManager.deleteComment(at: index, hardDelete: false) { [weak self] (isSuccess) in
                let alertMessage = isSuccess ? "Comment successfully deleted" : "Error while deleting comment"
                self?.showAlert(alertMessage: alertMessage)
            }
        case CommentItemDefaultAction.hardDelete.id:
            commentManager.deleteComment(at: index, hardDelete: true) { [weak self] (isSuccess) in
                let alertMessage = isSuccess ? "Comment successfully deleted" : "Error while deleting comment"
                self?.showAlert(alertMessage: alertMessage)
            }
        case CommentItemDefaultAction.flag(isFlagged: true).id:
            commentManager.unflagComment(at: index) { [weak self] (isSuccess) in
                let alertMessage = isSuccess ? "Comment successfully unflagged" : "Error while unflagging comment"
                self?.showAlert(alertMessage: alertMessage)
            }
        case CommentItemDefaultAction.flag(isFlagged: false).id:
            commentManager.flagComment(at: index) { [weak self] (isSuccess) in
                let alertMessage = isSuccess ? "Comment successfully flagged" : "Error while flagging comment"
                self?.showAlert(alertMessage: alertMessage)
            }
        default:
            fatalError("Implementation not found for action \(action.title)")
        }
    }
        
    private func showAlert(alertMessage: String) {
        
        let alert = UIAlertController(title: "", message: alertMessage, preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func displayNewPostsScreen(isEditMode: Bool) {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: NewUserPostsViewController.identifier) as! NewUserPostsViewController
        controller.currentMode = isEditMode ? .edit(type: .comment) : .create(type: .comment)
        controller.commentManager = commentManager
        controller.delegate = self
        if #available(iOS 13.0, *) {
            // Prevents screen to dismiss when swiping down on ios 13
            controller.isModalInPresentation = true
        }
        
        self.present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
    }
}

extension UserPostCommentsViewController: KeyboardServiceDelegate {

    // MARK: KeyboardServiceDelegate
    
    func keyboardWillChange(service: KeyboardService,
                            height: CGFloat,
                            animationDuration duration: TimeInterval) {
        let offset = height > 0 ? view.safeAreaInsets.bottom : 0
        inputContainerBottomConstraint.constant = height - offset
        
        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded()
        let count = commentManager.getNumberOfCommentItems()
        if count > 0 {
            // Scroll to bottom
            commentsTableView.layoutIfNeeded()
            let indexPath: IndexPath = IndexPath(item: Int(count) - 1, section: 0)
            commentsTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}

extension UserPostCommentsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == membersTableView {
            return mentionManager?.itemsCount ?? 0
        }
        return commentManager.getNumberOfCommentItems()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == membersTableView {
            guard let sampleAppCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? SampleAppTableViewCell else { return UITableViewCell() }
            if let model = mentionManager?.item(at: indexPath) {
                sampleAppCell.titleLabel?.text = model.displayName
            }
            
            return sampleAppCell
        }
        
        let item = commentManager.getCommentItem(at: indexPath.row)
        switch item {
        case .parent(let comment):
            let cell = tableView.dequeueReusableCell(withIdentifier: CommentViewCell.identifier, for: indexPath) as! CommentViewCell
            cell.configureCell(withComment: comment)
            if !comment.isDeleted {
                cell.moreButtonAction = { [weak self] in
                    self?.commentManager.prepareToFlagComment(at: indexPath.row)
                    self?.commentManager.isFlaggedByMe(onCompletion: { isFlaggedByMe in
                        let actions: [CommentItemDefaultAction] = [.edit, .delete, .hardDelete, .flag(isFlagged: isFlaggedByMe)]
                        self?.displayMoreActions(title: "Options", actions: actions, at: indexPath.row)
                    })
                }
                cell.replyButtonAction = { [weak self] in
                    self?.replyLabel.text = "Reply to \(comment.displayName)"
                    self?.replyContainerView.isHidden = false
                    self?.commentManager.parentCommentId = self?.commentManager.getCommentId(at: indexPath.row)
                }
                cell.reactButtonAction = { [weak self] in
                    self?.commentManager.toggleReaction(at: indexPath.row)
                }
            }
            return cell
        case .child(let comment):
            let cell = tableView.dequeueReusableCell(withIdentifier: ChildCommentViewCell.identifier, for: indexPath) as! ChildCommentViewCell
            cell.configure(withComment: comment)
            if !comment.isDeleted {
                cell.moreButtonAction = { [weak self] in
                    self?.displayMoreActions(title: "Options", actions: [CommentItemDefaultAction.edit, CommentItemDefaultAction.delete], at: indexPath.row)
                }
            }
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == membersTableView {
            return 40.0
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if tableView == membersTableView {
            if indexPath.row == (mentionManager?.itemsCount ?? 0) - 4 {
                mentionManager?.loadMore()
            }
        }
    }

}

extension UserPostCommentsViewController: UITableViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let frameHeight = scrollView.frame.size.height
        let contentOffset = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        let distanceFromBottom = contentHeight - contentOffset
        if distanceFromBottom < frameHeight {
            commentManager.loadMoreComments()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView != membersTableView { return }
        mentionManager?.addMention(from: textView, in: textView.text ?? "", at: indexPath)
    }
}

// MARK: UITextViewDelegate
extension UserPostCommentsViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            setPlaceholder()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            sendTextComment()
            textView.resignFirstResponder()
            return true
        }
        
        if (textView.text ?? "").count > AmityMentionManager.maximumCharacterCountForPost {
            showAlertForMaximumCharacters()
            return false
        }
        
        return mentionManager?.shouldChangeTextIn(textView, inRange: range, replacementText: text, currentText: textView.text ?? "") ?? true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        mentionManager?.changeSelection(textView)
    }
}

extension UserPostCommentsViewController: NewUserPostsViewControllerDelegate {
    func newUserPostsViewControllerDidCreateNewPost(_ controller: NewUserPostsViewController) {
    }
    
    func newUserPostsViewControllerDidUpdateComment() {
        fetchComments()
    }
}

extension UserPostCommentsViewController: AmityMentionManagerDelegate {
    func didGetUsers(users: [AmityMentionUserModel]) {
        if users.isEmpty {
            tableViewHeightConstraint.constant = 0
            membersTableView.isHidden = true
        } else {
            var heightConstraint: CGFloat = 240.0
            if users.count < 5 {
                heightConstraint = CGFloat(users.count) * 52.0
            }
            tableViewHeightConstraint.constant = heightConstraint
            membersTableView.isHidden = false
            membersTableView.reloadData()
        }
    }
    
    func didCreateAttributedString(attributedString: NSAttributedString) {
        textView.attributedText = attributedString
    }
    
    func didMentionsReachToMaximumLimit() {
        let message = "Mentions are reached to maximum limit"
        let alertController = UIAlertController(title: "Unable to mention", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Done", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func didCharactersReachToMaximumLimit() {
        showAlertForMaximumCharacters()
    }
    
    private func showAlertForMaximumCharacters() {
        let title = "Unable to mention"
        let message = "Text reached to maximum characters limit"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Done", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
