//
//  AmityChatViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 8/7/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import Foundation
import Photos
import MobileCoreServices

final class AmityChatViewController: UIViewController,
                                   UIImagePickerControllerDelegate,
                                   UINavigationControllerDelegate,
                                   UITextFieldDelegate,
                                   UIDocumentPickerDelegate,
                                   KeyboardServiceDelegate,
                                   CommentsDelegate,
                                   AmityCustomViewControllerDelegate {
    
    private lazy var titleButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self,
                         action: #selector(updateChannelDisplayName),
                         for: .touchUpInside)
        button.clipsToBounds = true
        return button
    }()
    
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var inputContainer: UIView!
    @IBOutlet private weak var bottom: NSLayoutConstraint!
    
    private var channelObject: AmityObject<AmityChannel>?
    private var channelToken: AmityNotificationToken?
        
    private var messagesTableViewController: AmityMessagesTableViewController?
    private var commentsTableViewController: AmityCommentsTableViewController?
    
    // To be injected.
    var client: AmityClient!
    
    // To be injected.
    var channelId: String!
    
    lazy var messageRepository = AmityMessageRepository(client: self.client)
    lazy var channelRepository = AmityChannelRepository(client: self.client)
    lazy var fileRepository = AmityFileRepository(client: self.client)
    
    // MARK: Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        KeyboardService.shared.delegate = self
        let channelPartecipation = AmityChannelParticipation(client: client,
                                                             andChannel: channelId)
        channelPartecipation.startReading()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let channelPartecipation = AmityChannelParticipation(client: client,
                                                             andChannel: channelId)
        channelPartecipation.stopReading()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.delegate = self
        
        navigationItem.titleView = titleButton
        addLeaveButton()
        addSettingsButton()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.destination {
        case let messagesTableViewController as AmityMessagesTableViewController:
            self.messagesTableViewController = messagesTableViewController
            messagesTableViewController.client = client
            messagesTableViewController.channelId = channelId
        case let commentsTableViewController as AmityCommentsTableViewController:
            self.commentsTableViewController = commentsTableViewController
            commentsTableViewController.client = client
            commentsTableViewController.channelId = channelId
            commentsTableViewController.delegate = self
        default:
            break
        }
    }
    
    @IBAction private func showImagePickerRequest(_ sender: UIButton) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] _ in
                self?.showImagePickerRequest(sender)
            }
        case .denied,
             .restricted:
            Log.add(info: "No authorization 🙈")
        case .authorized:
            showImagePicker()
        @unknown default:
            break
        }
    }
    
    private func showImagePicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        
        DispatchQueue.main.async {
            
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.delegate = self
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction private func didPressSend(_ sender: UIButton) {
        sendTextMessage()
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let imageURL = info[.imageURL] as? URL else { return }
        
        sendImageMessage(imageURL)
    }
    
    var msgObject: AmityObject<AmityMessage>?
    var msgToken: AmityNotificationToken?
    
    private func sendImageMessage(_ imageURL: URL) {
        msgObject = messageRepository.createImageMessage(withChannelId: channelId, imageFile: imageURL, caption: nil, fullImage: true, tags: nil, parentId: messagesTableViewController?.replyToMessageId)
        msgToken = msgObject?.observe({ (object, error) in
            
            guard let message = object.object else { return }
            
            Log.add(info: "\n--- Message Observer ---\n")
            Log.add(info: "Data Status: \(object.dataStatus.description)")
            Log.add(info: "Error: \(error)")
            Log.add(info: "Message Id: \(message.messageId)")
            Log.add(info: "Message Sync State: \(message.syncState.description)")
            
            let imageData = message.getImageInfo()
            Log.add(info: "Message Image Id: \(imageData?.fileId)")
            Log.add(info: "Message Image URL: \(imageData?.fileURL)")
            Log.add(info: "Message Image attributes: \(imageData?.attributes)")
            
        })
        
        messagesTableViewController?.replyToMessageId = nil
    }
    
    var messageObject: AmityObject<AmityMessage>?
    var messageToken: AmityNotificationToken?
    
    private func sendTextMessage() {
        guard
            let text: String = textField.text,
            !text.isEmpty
        else { return }
        textField.text = ""
        
        var parentId: String?
        if let messagesTableViewController = self.messagesTableViewController {
            parentId = messagesTableViewController.replyToMessageId
            messagesTableViewController.replyToMessageId = nil
        } else if let commentsTableViewController = self.commentsTableViewController {
            parentId = commentsTableViewController.parentId
        }
        
        messageToken?.invalidate()
        
        messageObject = messageRepository.createTextMessage(withChannelId: channelId,
                                                            text: text,
                                                            tags: nil,
                                                            parentId: parentId)
        messageToken = messageObject?.observe({ (msg, error) in
            
            Log.add(info: "Data Status: \(msg.dataStatus.rawValue)")
            Log.add(info: "isEdited: \(String(describing: msg.object?.isEdited))")
            Log.add(info: "isMessageEdited: \(String(describing: msg.object?.isMessageEdited))")
            
        })
    }
    
    func joinChannel(channelId: String, type: AmityChannelType) {
        // Don't join to channel if type is conversation.
        if type == .conversation { return }
        channelObject = channelRepository.joinChannel(channelId)
        
        channelToken = channelObject?.observe { [weak self] (channel, error) in
            if error != nil, let nsError = error as NSError? {
                if nsError.code == 400304 {
                    let alertController = UIAlertController(title: "Can't join", message: "User is banned from a channel", preferredStyle: .alert)
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel) {_ in
                        self?.dismiss(animated: true, completion: nil)
                        self?.navigationController?.popViewController(animated: true)
                    }
                    
                    alertController.addAction(defaultAction)
                    self?.present(alertController, animated: true, completion: nil)
                }
                
                return
            }
            guard let channel: AmityChannel = self?.channelObject?.object else { return }
            self?.setDisplayName(channel.displayName)
        }
    }
    
    func seeComments(for parentId: String) {
        UserDefaults.standard.parentId = parentId
        guard
            let viewController: UIViewController = storyboard?.instantiateViewController(withIdentifier: "AmityComments"),
            let chatViewController = viewController as? AmityChatViewController
        else { return }
        chatViewController.channelId = channelId
        chatViewController.client = client
        chatViewController.joinChannel(channelId: channelId,
                                       type: .standard)
        navigationController?.pushViewController(chatViewController, animated: true)
    }
    
    private func addLeaveButton() {
        let leaveButton = UIBarButtonItem(title: "Leave",
                                          style: .plain,
                                          target: self,
                                          action: #selector(leave))
        navigationItem.setLeftBarButton(leaveButton,
                                        animated: true)
        navigationItem.leftItemsSupplementBackButton = true
    }
    
    private func addSettingsButton() {
        let gearGlyph = UIImage(named: "Settings")
        
        let settingsButton = UIBarButtonItem(image: gearGlyph,
                                             style: .plain,
                                             target: self,
                                             action: #selector(navigateToChannelSettingsView))
        let removeAvatarButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(removeChannelAvatar))
        let addAvatarButton = UIBarButtonItem(image: UIImage(systemName: "person"), style: .plain, target: self, action: #selector(addChannelAvatar))
        navigationItem.setRightBarButtonItems([settingsButton, removeAvatarButton, addAvatarButton], animated: true)
    }
    
    @objc private func navigateToChannelSettingsView() {
        let storyboard = UIStoryboard(name: "ChannelSettings", bundle: nil)
        let viewController = storyboard
            .instantiateViewController(withIdentifier: "ChannelSettingsTableViewController")
        guard
            let channelSettingsViewController = viewController as? ChannelSettingsTableViewController
        else { return }
        
        channelSettingsViewController.client = client
        channelSettingsViewController.channelId = channelId
        
        navigationController?.pushViewController(channelSettingsViewController,
                                                 animated: true)
    }
    
    
    
    @objc private func leave() {
        channelRepository.leaveChannel(channelId) { [weak self] (success, error) in
            if success {
                self?.navigationController?.popViewController(animated: true)
            } else {
                Log.add(info: error ?? "")
            }
        }
    }
    
    var updateToken: AmityNotificationToken?
    
    // add title button action
    @objc private func updateChannelDisplayName() {
        let alertController = UIAlertController(title: "Enter The New Channel Display Name",
                                                message: nil,
                                                preferredStyle: .alert)
        
        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard
                let textField: UITextField = alertController.textFields?.first,
                let textFieldText: String = textField.text,
                let channelId = self?.channelId else { return }
                        
            let updater = self?.channelRepository.updateChannel(channelId)
            updater?.setDisplayName(textFieldText)
            self?.updateToken = updater?.update().observe({ (liveChannel, error) in
                
                guard let channel = liveChannel.object else { return }
                
                self?.setDisplayName(textFieldText)
                
                self?.updateToken?.invalidate()
            })
        }
        alertController.addAction(renameAction)
        
        alertController.addTextField { [weak self] textField in
            textField.placeholder = self?.titleButton.title(for: .normal)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // add remove avatar button action
    @objc private func removeChannelAvatar() {
        let alertController = UIAlertController(title: "Remove Channel Avatar",
                                                message: nil,
                                                preferredStyle: .alert)
        
        let removeAction = UIAlertAction(title: "Remove image", style: .default) { [weak self] _ in
            guard
                let client = self?.client,
                let channelId = self?.channelId else { return }
            
            let updater = self?.channelRepository.updateChannel(channelId)
            updater?.setAvatar(nil)
            self?.updateToken = updater?.update().observe({ [weak self] (liveChannel, error) in
                Log.add(info: "Update Status: \(String(describing: error))")
                self?.updateToken?.invalidate()
            })
            
        }
        alertController.addAction(removeAction)
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func addChannelAvatar() {
        let alertController = UIAlertController(title: "Add Channel Avatar",
                                                message: nil,
                                                preferredStyle: .alert)
        
        let removeAction = UIAlertAction(title: "Add clock image", style: .default) { [weak self] _ in
            guard
                let client = self?.client,
                let channelId = self?.channelId else { return }
            
            self?.fileRepository.uploadImage(UIImage(systemName: "clock")!, progress: nil, completion: { [weak self] (imageData, error) in
                guard let strongSelf = self else { return }
                
                if let uploadData = imageData {
                    let updater = self?.channelRepository.updateChannel(channelId)
                    updater?.setAvatar(uploadData)
                    self?.updateToken = updater?.update().observe({ [weak self] (liveChannel, error) in
                        
                        Log.add(info: "Avatar Update: \(error)")
                        
                        self?.updateToken?.invalidate()
                    })
                    
                }
                
            })

        }
        alertController.addAction(removeAction)
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func setDisplayName(_ channelDisplayName: String?) {
        let newTitleText: String
        if
            let channelName: String = channelDisplayName,
            !channelName.isEmpty {
            newTitleText = channelName
        } else {
            newTitleText = "@\(channelId!)"
        }
        titleButton.setTitle(newTitleText, for: .normal)
        titleButton.sizeToFit()
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTextMessage()
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
        
        for child in children {
            switch child {
            case let messagesTableViewController as AmityMessagesTableViewController:
                messagesTableViewController.scrollToBottom()
            case let commentsTableViewController as AmityCommentsTableViewController:
                commentsTableViewController.scrollToBottom()
            default:
                break
            }
        }
    }
    
    @IBAction func handleFileUploadButton(_ sender: Any) {
        let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypePDF)], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .fullScreen
        present(importMenu, animated: true, completion: nil)
    }
    
    @IBAction func handleCustomButton(_ sender: Any) {
        let vc = AmityCustomViewController.makeViewController()
        (vc as? AmityCustomViewController)?.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let myURL = urls.first else { return }
        
        msgObject = messageRepository.createFileMessage(withChannelId: channelId, file: myURL, filename: nil, caption: nil, tags: nil, parentId: messagesTableViewController?.replyToMessageId)
        
        msgToken?.invalidate()
        msgToken = msgObject?.observe({ (liveMessage, error) in
            Log.add(info: "Audio Message Status: \(liveMessage.dataStatus.description)")
            Log.add(info: "Audio Message Sync State: \(String(describing: liveMessage.object?.syncState.description))")
            Log.add(info: "Audio Message Error: \(String(describing: error))")
        })
        
        messagesTableViewController?.replyToMessageId = nil
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - AmityCustomViewControllerDelegate
    
    func amityCustom(_ viewController: AmityCustomViewController, willSendCustomDataWithData data: [String : Any]) {
        messageRepository.createCustomMessage(withChannelId: channelId, data: data, tags: nil, parentId: nil)
    }
    
    func amityCustom(_ viewController: AmityCustomViewController, willSendVoiceMessageWithData audioFileURL: URL, fileName: String) {
        
        msgObject = messageRepository.createAudioMessage(withChannelId: channelId, audioFile: audioFileURL, fileName: fileName, parentId: nil, tags: [])
        msgToken?.invalidate()
        
        msgToken = msgObject?.observe({ (liveMessage, error) in
            Log.add(info: "Audio Message Status: \(liveMessage.dataStatus.description)")
            Log.add(info: "Audio Message Sync State: \(String(describing: liveMessage.object?.syncState.description))")
            Log.add(info: "Audio Message Error: \(String(describing: error))")
        })
        
        messagesTableViewController?.replyToMessageId = nil
    }
    
    func amityCustom(_ viewController: AmityCustomViewController, willUpdateCustomDataWithData data: [String : Any], onMessage message: AmityMessage?) {
        // Intentionally left empty
    }
}
