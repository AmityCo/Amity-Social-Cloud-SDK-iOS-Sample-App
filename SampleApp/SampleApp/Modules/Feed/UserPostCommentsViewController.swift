//
//  UserPostCommentsViewController.swift
//  SampleApp
//
//  Created by Michael Abadi on 10/06/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit

class UserPostCommentsViewController: UIViewController, UITextFieldDelegate {
    
    var client: EkoClient?
    var commentManager: UserPostCommentManager!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputContainer: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var replyContainerView: UIView!
    @IBOutlet weak var replyLabel: UILabel!
    @IBOutlet weak var bottom: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queryOptionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(onQueryOptionButtonTap))
        self.navigationItem.rightBarButtonItem = queryOptionButton
        
        textField.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.reloadData()
        replyContainerView.isHidden = true
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
        fetchComments()
    }
    
    func fetchComments() {
        commentManager.observeCommentFeedChanges { [weak self] in
           self?.tableView.reloadData()
        }
    }
    
    @IBAction func handleSendButton(_ sender: Any) {
        sendTextComment()
    }
    
    @IBAction func replyDismissButton(_ sender: Any) {
        commentManager.parentCommentId = nil
        replyContainerView.isHidden = true
    }
    
    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTextComment()
        return true
    }

    // MARK: KeyboardServiceDelegate

    func keyboardWillChange(service: KeyboardService,
                            height: CGFloat,
                            animationDuration duration: TimeInterval) {
        let offset = height > 0 ? view.safeAreaInsets.bottom : 0
        bottom.constant = -height + offset

        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded()
        let count = commentManager.getNumberOfCommentItems()
        if count > 0 {
            // Scroll to bottom
            tableView.layoutIfNeeded()
            let indexPath: IndexPath = IndexPath(item: Int(count) - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    private func sendTextComment() {
        guard
            let text: String = textField.text,
            !text.isEmpty
            else { return }
        textField.text = ""

        commentManager.createComment(text: text)
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
            commentManager.deleteComment(at: index) { [weak self] (isSuccess) in
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
        controller.currentMode = isEditMode ? .edit(type: .comment) : .create
        controller.commentManager = commentManager
        if #available(iOS 13.0, *) {
            // Prevents screen to dismiss when swiping down on ios 13
            controller.isModalInPresentation = true
        }
        
        self.present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
    }
}

extension UserPostCommentsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentManager.getNumberOfCommentItems()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = commentManager.getCommentItem(at: indexPath.row)
        switch item {
        case .parent:
            return tableView.dequeueReusableCell(withIdentifier: CommentViewCell.identifier, for: indexPath)
        case .child:
            return tableView.dequeueReusableCell(withIdentifier: ChildCommentViewCell.identifier, for: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let item = commentManager.getCommentItem(at: indexPath.row)
        
        switch item {
        case .parent(let comment):
            let cell = cell as? CommentViewCell
            cell?.configure(displayName: comment.displayName, comment: comment.text, displayImage: nil)
            cell?.reactionLabel.text = comment.reaction
            
            cell?.moreButtonAction = { [weak self] in
                self?.commentManager.prepareToFlagComment(at: indexPath.row)
                self?.commentManager.isFlaggedByMe(onCompletion: { isFlaggedByMe in
                    self?.displayMoreActions(title: "Options", actions: [CommentItemDefaultAction.edit, CommentItemDefaultAction.delete, CommentItemDefaultAction.flag(isFlagged: isFlaggedByMe)], at: indexPath.row)
                })
            }
            cell?.replyButtonAction = { [weak self] in
                self?.replyLabel.text = "Reply to \(comment.displayName)"
                self?.replyContainerView.isHidden = false
                self?.commentManager.parentCommentId = self?.commentManager.getCommentId(at: indexPath.row)
            }
            cell?.reactButtonAction = { [weak self] in
                self?.commentManager.toggleReaction(at: indexPath.row)
            }
        case .child(let comment):
            let cell = cell as? ChildCommentViewCell
            cell?.configure(displayName: comment.displayName, comment: comment.text, displayImage: nil)
            break
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
}
