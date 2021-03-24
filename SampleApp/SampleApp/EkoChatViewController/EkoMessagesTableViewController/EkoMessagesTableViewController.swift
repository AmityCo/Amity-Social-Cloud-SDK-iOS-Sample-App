//
//  EkoMessagesTableViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/13/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import EkoChat

private let kContentOffsetY: CGFloat = 10
private let kContentOffsetX: CGFloat = 0

final class EkoMessagesTableViewController: UITableViewController, DataSourceListener, UIDocumentInteractionControllerDelegate, EkoEditMessageViewControllerDelegate, EkoCustomViewControllerDelegate, EkoAddReactionsDelegate, EkoChatTextTableViewCellDelegate {
    
    @objc var client: EkoClient!
    @objc var channelId: String!
    
    private var reversePreference: Bool {
        get { return UserDefaults.standard.channelReversePreference[channelId] ?? true }
        set { UserDefaults.standard.channelReversePreference[channelId] = newValue }
    }
    
    private lazy var flagManager = FlagManager(client: client, viewController: self)
    private lazy var tagManager = TagManager(client: client, viewController: self)
    private var messageReactors: [EkoMessageReactor] = []
    
    private var dataSource: MessageDataSource?
    private var reactionDataSource: ReactionDatasource?
    
    private lazy var reactionRepo = EkoReactionRepository(client: client)
    
    var messageRepository: EkoMessageRepository?
    
    let audioManager = AudioMessageHandler()
    
    /// If set, the next message created by the user will be a child of this
    /// message.
    var replyToMessageId: String?
    
    private func getReactionDatasource(messageId: String) -> ReactionDatasource? {
        let reactionCollection: EkoCollection<EkoReaction>
        
        reactionCollection = reactionRepo.getAllReactions(messageId, referenceType: .message)
        
        return ReactionDatasource(reactionsCollection: reactionCollection, reverse: false)
    }
    
    private func getUserRepository() -> EkoUserRepository {
        return EkoUserRepository(client: client)
    }
    
    private func observeMessages() {
        messageRepository = EkoMessageRepository(client: client)
        let userDefaults: UserDefaults = .standard
        
        let includingTags: [String] = userDefaults.channelPreferenceIncludingTags[channelId] ?? []
        let excludingTags: [String] = userDefaults.channelPreferenceExcludingTags[channelId] ?? []
        
        let filterByParentIdActive: Bool = userDefaults.channelPreferenceFilterByParentIdActive[channelId] ?? false
        let parentId: String? = userDefaults.channelPreferenceFilterByParentId[channelId]
        
        let messagesCollection: EkoCollection<EkoMessage>
        messagesCollection = messageRepository!.messages(withChannelId: channelId,
                                                         includingTags: includingTags,
                                                         excludingTags: excludingTags,
                                                         filterByParentId: filterByParentIdActive,
                                                         parentId: parentId,
                                                         reverse: reversePreference)
        
        dataSource = MessageDataSource(messagesCollection: messagesCollection,
                                       reverse: reversePreference)
        dataSource?.dataSourceObserver = self
        didUpdateDataSource()
    }
    
    @objc func scrollToBottom() {
        guard let messageCount = dataSource?.numberOfMessages(), messageCount > 0 else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.tableView.layoutIfNeeded()
            let indexPath: IndexPath = IndexPath(item: messageCount - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: kContentOffsetY, left: kContentOffsetX,
                                              bottom: kContentOffsetY, right: kContentOffsetX)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        observeMessages()
        super.viewWillAppear(animated)
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.numberOfMessages() ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let message: EkoMessage = getMessage(for: indexPath),
            let cellIdentifier = cellIdentifier(for: message, client: client) else {
                return UITableViewCell()
        }
        
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        (cell as? EkoChatTableViewCell)?.display(message, client: client)
        (cell as? EkoChatTextTableViewCell)?.delegate = self
        return cell
    }
    
    private func getMessage(for indexPath: IndexPath) -> EkoMessage? {
        return dataSource?.message(for: indexPath)
    }
    
    private func cellIdentifier(for message: EkoMessage, client: EkoClient) -> String? {
        switch message.messageType {
        case .custom where message.userId == client.currentUserId:
            fallthrough
        case .text where message.userId == client.currentUserId:
            return "ChatTextMeCell"
        case .custom:
            return "ChatTextOtherCell"
        case .text:
            return "ChatTextOtherCell"
        case .image:
            return "ChatImageCell"
        case .file, .audio:
            return "ChatFileCell"
        @unknown default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let message: EkoMessage = getMessage(for: indexPath) else { return 0 }
        
        switch message.messageType {
        case .image:
            let width = message.data?["width"] as? CGFloat ?? 200
            let height =  message.data?["height"] as? CGFloat ?? 200
            let imageSize = CGSize(width: width, height: height)
            return self.height(for: imageSize, withinSize: CGSize(width: 200, height: 200)) + 14
        case .text, .custom, .file, .audio:
            fallthrough
        @unknown default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    private func height(for size: CGSize, withinSize newSize: CGSize) -> CGFloat {
        let aspectWidth: CGFloat = newSize.width / size.width
        let aspectHeight: CGFloat = newSize.height / size.height
        let aspectRatio: CGFloat = min(aspectWidth, aspectHeight)
        
        return size.height * aspectRatio
    }
    
    // MARK: UITableViewDelegate
    
    /// Consider a channel with the following messages:
    ///
    ///   ABC ... XYZ ⟶ last (newest) message
    ///   ↳ first (oldest) message
    ///
    /// Based on whether we load the messages in reverse or not, we need to load more
    /// messages at different times.
    /// Below we see the two possible configurations, the dots tell us what is the direction
    /// where we expect the next batch of messages to be displayed at, therefore we use this
    /// information to decide when to load based on the scrolling event.
    ///
    /// 1)                               2)
    ///   reverse = false                  reverse = true
    ///   (Chronological order)            (Non-chronological order)
    ///
    ///          +=======+                            .
    ///          |   A   |                            .
    ///          |   B   |                        +=======+
    ///          |   C   |                        |   X   |
    ///          |   .   |                        |   Y   |
    ///          |   .   |                        |   Z   |
    ///          |       |                        |       |
    ///
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                            withVelocity velocity: CGPoint,
                                            targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        switch reversePreference {
        case false:
            // load previous page when scrolled to the bottom
            let fullHeight = scrollView.contentSize.height
            
            if fullHeight.isLessThanOrEqualTo(scrollView.contentOffset.y + targetContentOffset.pointee.y) {
                dataSource?.loadMore()
            }
        case true:
            // load previous page when scrolled to the top
            if targetContentOffset.pointee.y.isLessThanOrEqualTo(0) {
                dataSource?.loadMore()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let flagAction = UIContextualAction(style: .destructive, title: "Flag Options") { [weak self] action, view, completion in
            guard let message = self?.getMessage(for: indexPath) else { return }
            self?.flagManager.displayFlagAlertController(for: message)
            completion(true)
        }
        
        let tagAction = UIContextualAction(style: .normal, title: "Set Tags") { [weak self] _, _, completion in
            guard let message = self?.getMessage(for: indexPath) else { return }
            self?.tagManager.displayTagAlertController(for: message)
            completion(true)
        }
        tagAction.backgroundColor = UIColor(named: "EkoGreen")
        
        let filterByParentIdAction = UIContextualAction(style: .normal, title: "Filter Childs") { [weak self] (_, _, completion) in
            guard let channelId = self?.channelId, let message = self?.getMessage(for: indexPath) else { return }
            
            let userDefaults: UserDefaults = .standard
            userDefaults.channelPreferenceFilterByParentIdActive[channelId] = true
            userDefaults.channelPreferenceFilterByParentId[channelId] = message.messageId
            self?.observeMessages()
            
            completion(true)
        }
        filterByParentIdAction.backgroundColor = UIColor(named: "EkoOrange")
        
        let replyToAction = UIContextualAction(style: .normal, title: "Reply To") { [weak self] (_, _, completion) in
            guard let message = self?.getMessage(for: indexPath) else { return }
            self?.replyToMessageId = message.messageId
            let alertController = UIAlertController(title: "Reply to set ✅", message: "Please send a normal message to reply to this message", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            self?.present(alertController, animated: true, completion: nil)
            
            completion(true)
        }
        
        let config = UISwipeActionsConfiguration(actions: [flagAction, tagAction, filterByParentIdAction, replyToAction])
        return config
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let message = getMessage(for: indexPath) else { return }
        
        if message.isDeleted {
            let alert = UIAlertController(title: "Error", message: "Message has been deleted", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            showAlertSheet(message: message)
        }
    }
    
    private func showRestrictionAlert() {
        let alert = UIAlertController(title: "Error", message: "You are not authorized for editing this message", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func showAlertSheet(message: EkoMessage) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.deleteAction(forMessage: message)
        }))
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak self] _ in
            self?.updateAction(forMessage: message)
        }))
        alert.addAction(UIAlertAction(title: "Add A Reaction", style: .default, handler: { [weak self] _ in
            self?.addReactionAction(forMessage: message)
        }))
        alert.addAction(UIAlertAction(title: "Remove A Reaction", style: .default, handler: { [weak self] _ in
            self?.removeReactionAction(forMessage: message)
        }))
        alert.addAction(UIAlertAction(title: "Show My Reaction", style: .default, handler: { [weak self] _ in
            self?.showMyReactionAction(forMessage: message)
        }))
        alert.addAction(UIAlertAction(title: "Show All Reaction", style: .default, handler: { [weak self] _ in
            self?.showAllReactions(forMessage: message)
        }))
        alert.addAction(UIAlertAction(title: "Delete Msg if Failed", style: .default, handler: { [weak self] _ in
            self?.deleteFailedMessage(message: message)
        }))
        
        if message.messageType == .audio {
            alert.addAction(UIAlertAction(title: "Play Audio", style: .default, handler: { [weak self] _ in
                self?.downloadFileFromMessage(message: message, completion: { (audioFileURL) in
                    DispatchQueue.main.async {
                        
                        self?.audioManager.prepareAudioPlayer(url: audioFileURL)
                        self?.audioManager.playAudioRecording()
                    }
                })
            }))
        }
        
        if message.messageType == .file {
            alert.addAction(UIAlertAction(title: "Download File", style: .default, handler: { [weak self] _ in
                
                self?.downloadFileFromMessage(message: message, completion: { (fileURL) in
                    DispatchQueue.main.async {
                        
                        let dc = UIDocumentInteractionController(url: fileURL)
                        dc.delegate = self
                        dc.presentPreview(animated: true)
                    }
                })
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Print Details", style: .default, handler: { action in
            
            Log.add(info: "\n---- Details ----")
            Log.add(info: "Message Id: \(message.messageId)")
            Log.add(info: "Channel Id: \(message.channelId)")
            Log.add(info: "Sync State: \(message.syncState.description)")
            Log.add(info: "Message Type: \(message.messageType.description)")
            Log.add(info: "File Id: \(String(describing: message.fileId))")
            Log.add(info: "File Info: \(String(describing: message.getFileInfo()?.attributes))")
            Log.add(info: "Image Info: \(String(describing: message.getImageInfo()?.attributes))")
            Log.add(info: "Data: \(String(describing: message.data?.description))")
            Log.add(info: "----------------- \n")
            
        }))
        
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func deleteFailedMessage(message: EkoMessage) {
        guard message.syncState == .error else { return }
        
        messageRepository?.deleteFailedMessage(message.messageId, completion: { (isSuccess, error) in
            Log.add(info: "Deleting Failed Message Status: \(isSuccess)")
            self.tableView.reloadData()
        })
    }
    
    // MARK: - Alert Sheet Action
    private func deleteAction(forMessage message: EkoMessage) {
        if message.userId != client.currentUserId {
            showRestrictionAlert()
        } else {
            let editor = EkoMessageEditor(client: client, messageId: message.messageId)
            editor.delete { [weak self] success, error in
                let alert = UIAlertController(title: nil, message: "Message succesfully deleted", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
                self?.tableView.reloadData()
            }
        }
    }
    
    private func updateAction(forMessage message: EkoMessage) {
        if message.userId != client.currentUserId {
            showRestrictionAlert()
        } else {
            if message.messageType == .text {
                guard let vc = EkoEditMessageViewController.make() as? EkoEditMessageViewController else { return }
                vc.delegate = self
                vc.setMessage(message: message)
                let nvc = UINavigationController(rootViewController: vc)
                navigationController?.present(nvc, animated: true, completion: nil)
            } else if message.messageType == .custom {
                guard let vc = EkoCustomViewController.makeViewController() as? EkoCustomViewController else { return }
                vc.setMessage(message: message)
                vc.delegate = self
                let nvc = UINavigationController(rootViewController: vc)
                navigationController?.present(nvc, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Error", message: "Message type not supported for editing", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func addReactionAction(forMessage message: EkoMessage) {
        guard let vc = EkoAddReactionsViewController.makeViewController() as? EkoAddReactionsViewController else { return }
        vc.setupView(type: .add, message: message)
        vc.delegate = self
        let nvc = UINavigationController(rootViewController: vc)
        navigationController?.present(nvc, animated: true, completion: nil)
    }
    
    private func removeReactionAction(forMessage message: EkoMessage) {
        guard let vc = EkoAddReactionsViewController.makeViewController() as? EkoAddReactionsViewController else { return }
        vc.setupView(type: .remove, message: message)
        vc.delegate = self
        let nvc = UINavigationController(rootViewController: vc)
        navigationController?.present(nvc, animated: true, completion: nil)
    }
    
    private func showMyReactionAction(forMessage message: EkoMessage) {
        guard let vc = EkoReactionsViewController.makeViewController() as? EkoReactionsViewController else { return }
        let myReactions = message.myReactions
        var reactionModel: [ReactionModel] = [ReactionModel]()
        for reaction in myReactions {
            reactionModel.append(ReactionModel(reaction: reaction as! String, user: "mySelf"))
        }
        vc.setMyReactions(reactionModel)
        let nvc = UINavigationController(rootViewController: vc)
        navigationController?.present(nvc, animated: true, completion: nil)
    }
    
    private func showAllReactions(forMessage message: EkoMessage) {
        guard let vc = EkoReactionsViewController.makeViewController() as? EkoReactionsViewController,
            let datasource = getReactionDatasource(messageId: message.messageId) else { return }
        vc.setDatasource(datasource, userRepo: getUserRepository())
        let nvc = UINavigationController(rootViewController: vc)
        navigationController?.present(nvc, animated: true, completion: nil)
    }
    
    // MARK: UIDocumentInteractionController
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    // MARK: DataSourceListener
    
    func didUpdateDataSource() {
        tableView.reloadData()
        
        // scroll to last row on refresh
        scrollToBottom()
    }
    
    // MARK: EkoEditMessageViewControllerDelegate
    
    func ekoEdit(_ viewController: EkoEditMessageViewController, willUpdateText text: String, onMessage message: EkoMessage?) {
        guard let message = message else { return }
        let editor = EkoMessageEditor(client: client, messageId: message.messageId)
        editor.editText(text) { [weak self] success, error in
            self?.tableView.reloadData()
        }
    }
    
    // MARK: EkoCustomViewControllerDelegate
    
    func ekoCustom(_ viewController: EkoCustomViewController, willSendCustomDataWithData data: [String : Any]) {
        // Intentionally left empty
    }
    
    func ekoCustom(_ viewController: EkoCustomViewController, willSendVoiceMessageWithData data: Data, fileName: String) {
        // Intentionally left empty
    }
    
    func ekoCustom(_ viewController: EkoCustomViewController, willUpdateCustomDataWithData data: [String : Any], onMessage message: EkoMessage?) {
        guard let message = message else { return }
        let editor = EkoMessageEditor(client: client, messageId: message.messageId)
        editor.editCustomMessage(data) { [weak self] success, error in
            self?.tableView.reloadData()
        }
    }
    
    // MARK: EkoAddReactionsDelegate
    func didSendReaction(_ viewController: EkoAddReactionsViewController, withReactionName reaction: String, message: EkoMessage?) {
        guard let message = message else { return }
        sendReaction(with: message, reaction: reaction)
    }
    
    func didRemoveReaction(_ viewController: EkoAddReactionsViewController, withReactionName reaction: String, message: EkoMessage?) {
        guard let message = message else { return }
        removeReaction(with: message, reaction: reaction)
    }
    
    private func sendReaction(with message: EkoMessage, reaction: String) {
        let messageReactor: EkoMessageReactor?
        if let index = messageReactors.firstIndex(where: { $0.message.messageId == message.messageId }) {
            messageReactor = messageReactors[index]
        } else {
            messageReactor = EkoMessageReactor(client: client, message: message)
        }
        messageReactor?.addReaction(withReaction: reaction, completion: { [weak self] success, error in
            let title = success ? "Success" : "Error"
            let message = success ? "Reaction \(reaction) added" : "\(error?.localizedDescription ?? "Error")"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let style: UIAlertAction.Style = success ? .default : .destructive
            alert.addAction(UIAlertAction(title: "OK", style: style, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        })
        if !messageReactors.contains(where: { $0.message.messageId == message.messageId }) {
            messageReactors.append(messageReactor!)
        }
    }
    
    private func removeReaction(with message: EkoMessage, reaction: String) {
        let messageReactor: EkoMessageReactor?
        if let index = messageReactors.firstIndex(where: { $0.message.messageId == message.messageId }) {
            messageReactor = messageReactors[index]
        } else {
            messageReactor = EkoMessageReactor(client: client, message: message)
        }
        messageReactor?.removeReaction(withReaction: reaction, completion: { [weak self] success, error in
            let title = success ? "Success" : "Error"
            let message = success ? "Reaction \(reaction) removed" : "\(error?.localizedDescription ?? "Error")"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let style: UIAlertAction.Style = success ? .default : .destructive
            alert.addAction(UIAlertAction(title: "OK", style: style, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        })
        if !messageReactors.contains(where: { $0.message.messageId == message.messageId }) {
            messageReactors.append(messageReactor!)
        }
    }
    
    // MARK: EkoChatTextTableViewCellDelegate
    
    func chatTextDidReact(_ cell: EkoChatTextTableViewCell, withReaction reaction: String) {
        guard let indexPath = tableView.indexPath(for: cell), let message = dataSource?.message(for: indexPath) else { return }
        if message.myReactions.contains(reaction) {
            removeReaction(with: message, reaction: reaction)
        } else {
            sendReaction(with: message, reaction: reaction)
        }
    }
    
    // Helpers
    func downloadFileFromMessage(message: EkoMessage, completion: @escaping (URL) -> Void) {
        do {
            var fileName = message.messageId
            if message.syncState == .synced {
                let fileInfo = message.getFileInfo()
                let fileExtension = fileInfo?.attributes["extension"] as? String ?? ""
                fileName += ".\(fileExtension)"
            } else {
                let fileInfo = message.getFileInfo()
                fileName = fileInfo?.fileName ?? ""
            }
            
            Log.add(info: "File Name: \(fileName)")
            
            let cacheDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let destination = cacheDirectory.appendingPathComponent(fileName)
            
            downloadData(message: message, destination: destination) { (fileURL) in
                completion(fileURL)
            }
            
        } catch let err {
            Log.add(info: "File Download Error \(err)")
        }
    }
    
    func downloadData(message: EkoMessage, destination: URL, completion: @escaping (URL) -> Void) {
        messageRepository?.downloadFile(for: message, completion: { (data, error) in
            if let err = error {
                Log.add(info: "Error occurred while downloading \(err)")
                return
            }
            
            guard let audioData = data else {
                Log.add(info: "Media data not found")
                return
            }
            
            do {
                try audioData.write(to: destination)
                completion(destination)
            } catch {
                Log.add(info: "Error when writing media data")
            }
        })
    }
    
}

extension EkoFileData {
    
    var fileName: String {
        return self.attributes["name"] as? String ?? ""
    }
}
