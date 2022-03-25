//
//  AmityChatViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 8/7/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices
import AmitySDK

private let reuseIdentifier = "SampleAppTableViewCell"

final class AmityChatViewController: UIViewController,
                                   UIImagePickerControllerDelegate,
                                   UINavigationControllerDelegate,
                                   UITextViewDelegate,
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
    
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var inputContainer: UIView!
    @IBOutlet private weak var bottom: NSLayoutConstraint!
    @IBOutlet private weak var membersTableView: UITableView!
    @IBOutlet private weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    private var channelObject: AmityObject<AmityChannel>?
    private var channelToken: AmityNotificationToken?
        
    private var messagesTableViewController: AmityMessagesTableViewController?
    private var commentsTableViewController: AmityCommentsTableViewController?
    
    private var channelType: AmityChannelType = AmityChannelType.standard
    
    private var mentionManager: AmityMentionManager?
    
    // To be injected.
    var client: AmityClient!
    
    // To be injected.
    var channelId: String!
    
    var msgObject: AmityObject<AmityMessage>?
    var msgToken: AmityNotificationToken?
    
    lazy var messageRepository = AmityMessageRepository(client: self.client)
    lazy var channelRepository = AmityChannelRepository(client: self.client)
    lazy var fileRepository = AmityFileRepository(client: self.client)
    lazy var channelPartecipation = AmityChannelParticipation(client: client,
                                                         andChannel: channelId)
    
    var messageObject: AmityObject<AmityMessage>?
    var messageToken: AmityNotificationToken?
    
    // MARK: Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        KeyboardService.shared.delegate = self
        
        channelPartecipation.startReading()
        mentionManager?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        channelPartecipation.stopReading()
        
        mentionManager?.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        setPlaceholder()
        
        navigationItem.titleView = titleButton
        addLeaveButton()
        addSettingsButton()
        
        let nib = UINib(nibName: "SampleAppTableViewCell", bundle: nil)
        membersTableView?.register(nib, forCellReuseIdentifier: reuseIdentifier)
        
        membersTableView?.tableFooterView = UIView()
        
        hideMentionsTableView()
        
        setupMentionManager()
    }
    
    private func setupMentionManager() {
        mentionManager = AmityMentionManager(withType: .message(channelId: channelId))
        mentionManager?.delegate = self
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
    
    private func hideMentionsTableView() {
        tableViewHeightConstraint.constant = 0
        membersTableView?.isHidden = true
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
    
    private func sendImageMessage(_ imageURL: URL) {
        
        let messageId = messageRepository.createImageMessage(withChannelId: channelId, imageFile: imageURL, caption: nil, fullImage: true, tags: nil, parentId: messagesTableViewController?.replyToMessageId, completion: nil)
        
        msgObject = messageRepository.getMessage(messageId)
        
        msgToken = msgObject?.observe({ (object, error) in
            guard let message = object.object else {
                return
            }
            
            Log.add(info: "\n--- Message Observer ---\n")
            Log.add(info: "Data Status: \(object.dataStatus.description)")
            Log.add(info: "Error: \(String(describing: error))")
            Log.add(info: "Message Id: \(message.messageId)")
            Log.add(info: "Message Sync State: \(message.syncState.description)")
            
            guard let imageData = message.getImageInfo() else {
                Log.add(info: "Message Image: imageData not found")
                return
            }
            
            Log.add(info: "Message Image Id: \(imageData.fileId)")
            Log.add(info: "Message Image URL: \(imageData.fileURL)")
            Log.add(info: "Message Image attributes: \(imageData.attributes)")
            
        })
        
        messagesTableViewController?.replyToMessageId = nil
    }
    
    private func sendTextMessage() {
        guard let text: String = textView.text, !text.isEmpty else { return }
        textView.text = ""

        var parentId: String?
        if let messagesTableViewController = self.messagesTableViewController {
            parentId = messagesTableViewController.replyToMessageId
            messagesTableViewController.replyToMessageId = nil
        } else if let commentsTableViewController = self.commentsTableViewController {
            parentId = commentsTableViewController.parentId
        }
        
        messageToken?.invalidate()
        let metadata = mentionManager?.getMetadata()
        let mentionees = mentionManager?.getMentionees()
        
        if let mentionees = mentionees, let metadata = metadata {
            let messageId = messageRepository.createTextMessage(channelId: channelId, text: text, tags: nil, parentId: parentId, metadata: metadata, mentionees: mentionees)
            messageObject = messageRepository.getMessage(messageId)
        } else {
            let messageId = messageRepository.createTextMessage(withChannelId: channelId, text: text, tags: nil, parentId: parentId, completion: nil)
            messageObject = messageRepository.getMessage(messageId)
        }
          
        mentionManager?.resetState()
        
        messageToken = messageObject?.observe({ (msg, error) in
            Log.add(info: "Data Status: \(msg.dataStatus.rawValue)")
            Log.add(info: "isEdited: \(String(describing: msg.object?.isEdited))")
            Log.add(info: "isMessageEdited: \(String(describing: msg.object?.isMessageEdited))")
            
        })
    }
    
    func joinChannel(channelId: String, type: AmityChannelType) {
        // Don't join to channel if type is conversation.
        if type == .conversation { return }
        
        channelType = type
        
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
                if let error = error {
                    var description = error.localizedDescription
                    let code = (error as NSError).code
                    if code == AmityErrorCode.moderatorUnableToLeaveCommunity.rawValue {
                        description = "You’re the only moderator in this group. To leave community, nominate other members to moderator role."
                    }
                    
                    let alertController = UIAlertController(title: "Unable to leave community", message: description, preferredStyle: .alert)
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel) {_ in
                        self?.dismiss(animated: true, completion: nil)
                    }
                    
                    alertController.addAction(defaultAction)
                    self?.present(alertController, animated: true, completion: nil)
                }
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
                        
            let builder = AmityChannelUpdateBuilder(channelId: channelId)
            builder.setDisplayName(textFieldText)
            
            self?.updateToken = self?.channelRepository.updateChannel(with: builder).observe({ (liveChannel, error) in
                guard let _ = liveChannel.object else {
                    return
                }
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
                let _ = self?.client,
                let channelId = self?.channelId else { return }
            
            let builder = AmityChannelUpdateBuilder(channelId: channelId)
            builder.setAvatar(nil)
            
            self?.updateToken = self?.channelRepository.updateChannel(with: builder).observe({ [weak self] (liveChannel, error) in
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
                let _ = self?.client,
                let channelId = self?.channelId else { return }
            
            self?.fileRepository.uploadImage(UIImage(systemName: "clock")!, progress: nil, completion: { [weak self] (imageData, error) in
                guard let _ = self else { return }
                
                if let uploadData = imageData {
                    
                    let builder = AmityChannelUpdateBuilder(channelId: channelId)
                    builder.setAvatar(uploadData)
                    
                    self?.updateToken = self?.channelRepository.updateChannel(with: builder).observe({ [weak self] (liveChannel, error) in
                        Log.add(info: "Avatar Update: \(String(describing: error))")
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
    
    private func setPlaceholder() {
        textView.text = "Enter message here"
        textView.textColor = UIColor.lightGray
    }
    
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
        if (textView.text ?? "").count > AmityMentionManager.maximumCharacterCountForPost {
            showAlertForMaximumCharacters()
            return false
        }
        
        return mentionManager?.shouldChangeTextIn(textView, inRange: range, replacementText: text, currentText: textView.text ?? "") ?? true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        mentionManager?.changeSelection(textView)
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
        
        let messageId = messageRepository.createFileMessage(withChannelId: channelId, file: myURL, filename: nil, caption: nil, tags: nil, parentId: messagesTableViewController?.replyToMessageId, completion: nil)
        
        msgObject = messageRepository.getMessage(messageId)
        
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
        
        let messageId = messageRepository.createAudioMessage(withChannelId: channelId, audioFile: audioFileURL, fileName: fileName, parentId: nil, tags: [], completion: nil)
        
        msgObject = messageRepository.getMessage(messageId)
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

extension AmityChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mentionManager?.addMention(from: textView, in: textView.text ?? "", at: indexPath)
    }
}

extension AmityChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mentionManager?.itemsCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sampleAppCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? SampleAppTableViewCell else { return UITableViewCell() }
        if let model = mentionManager?.item(at: indexPath) {
            sampleAppCell.titleLabel?.text = model.isChannel ? "@all: Notify everyone in this channel" : model.displayName
        }
        
        return sampleAppCell
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

extension AmityChatViewController: AmityMentionManagerDelegate {
    func didGetUsers(users: [AmityMentionUserModel]) {
        if users.isEmpty {
            tableViewHeightConstraint.constant = 0
            membersTableView.isHidden = true
        } else {
            var heightConstant:CGFloat = 240.0
            if users.count < 5 {
                heightConstant = CGFloat(users.count) * 52.0
            }
            tableViewHeightConstraint.constant = heightConstant
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
