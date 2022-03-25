//
//  NewUserPostsViewController.swift
//  SampleApp
//
//  Created by Nishan Niraula on 4/27/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit
import MobileCoreServices

protocol NewUserPostsViewControllerDelegate: AnyObject {
    func newUserPostsViewControllerDidCreateNewPost(_ controller: NewUserPostsViewController)
    func newUserPostsViewControllerDidUpdateComment()
}

/*
 * Note:
 *
 * This class displays the screen to edit/create new post.
 */
class NewUserPostsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var delegate: NewUserPostsViewControllerDelegate?
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var attachImageButton: UIButton!
    @IBOutlet weak var attachVideoButton: UIButton!
    @IBOutlet weak var imageCountLabel: UILabel!
    @IBOutlet weak var videoCountLabel: UILabel!
    @IBOutlet weak var filePostSwitch: UISwitch!
    
    // Poll IBOutlets
    @IBOutlet weak var pollPostSwitch: UISwitch!
    @IBOutlet weak var numberOfPollTextField: UITextField!
    @IBOutlet weak var numberOfDayToClosePollTextField: UITextField!
    @IBOutlet weak var pollMultipleVodeSwitch: UISwitch!
    @IBOutlet weak var pollView: UIView!
    
    @IBOutlet weak var communityPostSwitch: UISwitch!
    @IBOutlet weak var communityIdField: UITextField!
    @IBOutlet weak var streamIdTextField: UITextField!
    
    // Members tableview for mention
    @IBOutlet private weak var membersTableView: UITableView!
    @IBOutlet private weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    var attachedImages: [UIImage] = []
    var attachedVideoUrls: [URL] = []
    
    var feedManager: UserPostsFeedManager!
    var commentManager: UserPostCommentManager!
    var isPostEnabled = true
    
    private var mentionManager: AmityMentionManager?
    
    var communityId: String = ""
    var isCommunityPost: Bool = false
    
    enum ModeType {
        case post
        case comment
    }
    
    enum Mode {
        case create(type: ModeType = .post)
        case edit(type: ModeType = .post)
    }
    
    var currentMode: Mode = .create(type: .post)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        if let manager = feedManager, let community = manager.community {
            communityIdField.text = community.communityId
        }
        
        if let manager = commentManager {
            communityIdField.text = manager.communityId
        }
        
        setupMentionManager()
    }
    
    func setupViews() {
        scrollView.contentInset.bottom = 350
        textView.keyboardDismissMode = .onDrag
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.delegate = self
        attachImageButton.addTarget(self, action: #selector(onAttachImageButtonTap), for: .touchUpInside)
        attachVideoButton.addTarget(self, action: #selector(onAttachVideoButtonTap), for: .touchUpInside)
        updateViewsForCurrentMode()
        pollView.isHidden = true
        
        if isCommunityPost {
            communityPostSwitch.isOn = true
            communityIdField.text = communityId
        }

        let nib = UINib(nibName: "SampleAppTableViewCell", bundle: nil)
        membersTableView?.register(nib, forCellReuseIdentifier: "SampleAppTableViewCell")
        
        membersTableView?.tableFooterView = UIView()
        
        membersTableView.dataSource = self
        membersTableView.delegate = self
        
        hideMentionsTableView()
    }
    
    private func setupMentionManager() {
        var managerType: AmityMentionManagerType

        switch currentMode {
        case .create(let type), .edit(let type):
            if type == .comment {
                managerType = .comment(communityId: commentManager?.communityId)
            } else {
                managerType = .post(communityId: (feedManager?.community?.isPublic ?? true) ? nil : feedManager?.community?.communityId ?? "")
            }
        }

        mentionManager = AmityMentionManager(withType: managerType)
        mentionManager?.delegate = self

        switch currentMode {
        case .create:
            break
        case .edit(let type):
            var metadata: [String: Any]?
            var text = ""

            if type == .comment {
                let comment = commentManager?.getEditCommentData()
                text = comment?.text ?? ""
                metadata = comment?.metadata
            } else {
                let post = feedManager?.getEditPostData()
                text = post?.text ?? ""
                metadata = post?.metadata
            }

            if let metadata = metadata {
                mentionManager?.setMentions(metadata: metadata, inText: text)
            }
        }
    }
    
    func updateViewsForCurrentMode() {
        
        let postButton: UIBarButtonItem
        let cancelButton: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(onCancelButtonTap))
        
        
        switch currentMode {
        case .create(let type):
            self.title = "Create \(type == .comment ? "Comment" : "Post")"
            
            postButton = UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(onPostButtonTap))
        case .edit(let type):
            self.title = "Edit \(type == .comment ? "Comment" : "Post")"
            
            postButton = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(onPostButtonTap))
        }
        
        self.navigationItem.rightBarButtonItem = postButton
        self.navigationItem.leftBarButtonItem = cancelButton
    }
    
    @objc func onPostButtonTap() {
        
        guard isPostEnabled else { return }
        
        let postText = textView.text
        
        isPostEnabled = false
        
        let metadata = mentionManager?.getMetadata()
        let mentionees = mentionManager?.getMentionees()
        
        switch currentMode {
        case .create:
            
            let communityPostId = communityIdField.text ?? ""
            let isCommunityPost = communityPostSwitch.isOn && !communityPostId.isEmpty
            
            if pollPostSwitch.isOn {
                feedManager.createPollPost(text: postText, numOptions: numberOfPollTextField.text, numDayToClose: numberOfDayToClosePollTextField.text, isMultipleVote: pollMultipleVodeSwitch.isOn, communityId: isCommunityPost ? communityPostId : nil, metadata: metadata, mentionees: mentionees) { [weak self] isSuccess in
                    guard let strongSelf = self else { return }
                    strongSelf.isPostEnabled = true
                    strongSelf.showAlertAndDismiss(isSuccess: isSuccess)
                    strongSelf.delegate?.newUserPostsViewControllerDidCreateNewPost(strongSelf)
                }
            } else {
                feedManager.createPost(text: postText, images: attachedImages, videos: attachedVideoUrls, isFilePost: filePostSwitch.isOn, communityId: isCommunityPost ? communityPostId : nil, streamId: streamIdTextField.text, metadata: metadata, mentionees: metadata == nil ? nil : mentionees) { [weak self] isSuccess in
                    guard let strongSelf = self else { return }
                    strongSelf.isPostEnabled = true
                    strongSelf.showAlertAndDismiss(isSuccess: isSuccess)
                    strongSelf.delegate?.newUserPostsViewControllerDidCreateNewPost(strongSelf)
                }
            }
            
        case let .edit(type):
            if type == .post {
                feedManager.updatePost(text: postText, metadata: metadata, mentionees: mentionees) { [weak self] (isSuccess) in
                    self?.isPostEnabled = true
                    self?.showAlertAndDismiss(isSuccess: isSuccess)
                }
            } else {
                commentManager.updateComment(text: postText, metadata: metadata, mentionees: mentionees) { [weak self] (isSuccess) in
                    self?.isPostEnabled = true
                    self?.showAlertAndDismiss(isSuccess: isSuccess)
                    self?.delegate?.newUserPostsViewControllerDidUpdateComment()
                }
            }
        }
        
        attachedImages = []
    }
    
    func showAlertAndDismiss(isSuccess: Bool) {
        
        var alertMessage = isSuccess ? "Post successfully created" : "Error while creating post"
        if case .edit = currentMode {
            alertMessage = isSuccess ? "Post successfully updated" : "Error while updating post"
        }
        
        let alert = UIAlertController(title: "", message: alertMessage, preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .cancel, handler: { action in
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Create Poll
    @IBAction func onTapPollSwitch(_ sender: UISwitch) {
        pollView.isHidden = !sender.isOn
    }
    
    @objc func onCancelButtonTap() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func onAttachImageButtonTap() {
        showImagePicker()
    }
    
    @objc func onAttachVideoButtonTap() {
        showVideoPicker()
    }
    
    private func showImagePicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [String(kUTTypeImage)]
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    private func showVideoPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [String(kUTTypeMovie)]
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    private func hideMentionsTableView() {
        tableViewHeightConstraint.constant = 0
        membersTableView?.isHidden = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        if let mediaType = info[.mediaType] as? String {
            switch mediaType {
            case String(kUTTypeImage):
                if let image: UIImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    attachedImages.append(image)
                }
            case String(kUTTypeMovie):
                if let videoUrl = info[.mediaURL] as? URL {
                    attachedVideoUrls.append(videoUrl)
                }
            default:
                break
            }
            DispatchQueue.main.async {
                picker.dismiss(animated: true, completion: nil)
                self.imageCountLabel.text = "\(self.attachedImages.count) Image attached"
                self.videoCountLabel.text = "\(self.attachedVideoUrls.count) Video attached"
            }
        } else {
            assertionFailure("Unhandle media type for UIImagePickerController")
        }
    }
}

extension NewUserPostsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mentionManager?.addMention(from: textView, in: textView.text, at: indexPath)
    }
}

extension NewUserPostsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mentionManager?.itemsCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SampleAppTableViewCell") as? SampleAppTableViewCell else { return UITableViewCell() }
        
        if let model = mentionManager?.item(at: indexPath) {
            cell.titleLabel?.text = model.displayName
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == (mentionManager?.itemsCount ?? 0) - 4 {
            mentionManager?.loadMore()
        }
    }
}

extension NewUserPostsViewController: AmityMentionManagerDelegate {
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

extension NewUserPostsViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text.count > AmityMentionManager.maximumCharacterCountForPost {
            showAlertForMaximumCharacters()
            return false
        }
        return mentionManager?.shouldChangeTextIn(textView, inRange: range, replacementText: text, currentText: textView.text) ?? true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        mentionManager?.changeSelection(textView)
    }
}
