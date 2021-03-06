//
//  NewUserPostsViewController.swift
//  SampleApp
//
//  Created by Nishan Niraula on 4/27/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit
import MobileCoreServices

/*
 * Note:
 *
 * This class displays the screen to edit/create new post.
 */
// FIXME: Implement video post function
class NewUserPostsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var attachImageButton: UIButton!
    @IBOutlet weak var attachVideoButton: UIButton!
    @IBOutlet weak var imageCountLabel: UILabel!
    @IBOutlet weak var videoCountLabel: UILabel!
    @IBOutlet weak var filePostSwitch: UISwitch!
    @IBOutlet weak var communityPostSwitch: UISwitch!
    @IBOutlet weak var communityIdField: UITextField!
    
    var attachedImages: [UIImage] = []
    var attachedVideoUrls: [URL] = []
    
    var feedManager: UserPostsFeedManager!
    var commentManager: UserPostCommentManager!
    
    var isPostEnabled = true
    
    enum ModeType {
        case post
        case comment
    }
    
    enum Mode {
        case create
        case edit(type: ModeType = .post)
    }
    
    var currentMode: Mode = .create
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func setupViews() {
        textView.keyboardDismissMode = .onDrag
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        attachImageButton.addTarget(self, action: #selector(onAttachImageButtonTap), for: .touchUpInside)
        attachVideoButton.addTarget(self, action: #selector(onAttachVideoButtonTap), for: .touchUpInside)
        updateViewsForCurrentMode()
    }
    
    func updateViewsForCurrentMode() {
        
        let postButton: UIBarButtonItem
        let cancelButton: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(onCancelButtonTap))
        
        
        switch currentMode {
        case .create:
            self.title = "Create Post"
            
            postButton = UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(onPostButtonTap))
        case .edit(let type):
            self.title = "Edit Post"
            
            postButton = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(onPostButtonTap))
            
            
            if type == .comment {
                // Show that edited comment
                let comment = commentManager.getEditCommentData()
                textView.text = comment?.text
            } else {
                // Show that edited post
                let post = feedManager.getEditPostData()
                textView.text = post.text
            }
        }
        
        self.navigationItem.rightBarButtonItem = postButton
        self.navigationItem.leftBarButtonItem = cancelButton
    }
    
    @objc func onPostButtonTap() {
        
        guard isPostEnabled else { return }
        
        let postText = textView.text
        
        isPostEnabled = false
        
        switch currentMode {
        case .create:
            
            let communityPostId = communityIdField.text ?? ""
            let isCommunityPost = communityPostSwitch.isOn && !communityPostId.isEmpty
            feedManager.createPost(text: postText, images: attachedImages, videos: attachedVideoUrls, isFilePost: filePostSwitch.isOn, communityId: isCommunityPost ? communityPostId : nil) { [weak self] isSuccess in
                self?.isPostEnabled = true
                self?.showAlertAndDismiss(isSuccess: isSuccess)
            }
        case let .edit(type):
            if type == .post {
                feedManager.updatePost(text: postText) { [weak self] (isSuccess) in
                    self?.isPostEnabled = true
                    self?.showAlertAndDismiss(isSuccess: isSuccess)
                }
            } else {
                commentManager.updateComment(text: postText) { [weak self] (isSuccess) in
                    self?.isPostEnabled = true
                    self?.showAlertAndDismiss(isSuccess: isSuccess)
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
