//
//  HomeViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/30/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import EkoChat
import UserNotifications

final class HomeViewController: UIViewController, ChannelsTableViewControllerDelegate, MoreTableViewControllerDelegate, EkoClientErrorDelegate, ChannelCreator {
    
    @IBOutlet private weak var displayNameButton: UIButton!
    @IBOutlet private weak var totalMessageCountLabel: UILabel!

    private var connectionStatusObservationToken: NSKeyValueObservation?
    private var totalUnreadCountObservationToken: NSKeyValueObservation?

    // Only place where client should be held strongly
    var client: EkoClient!
    lazy var channelRepository = EkoChannelRepository(client: client)
    var channelType: EkoChannelType = .standard
    
    private var channelListViewController: ChannelListTableViewController!
    private var displayNameController: DisplayNameButtonController!
    private var unreadCountController: UnreadCountLabelController!

    // MARK: Lifecyle

    override func awakeFromNib() {
        super.awakeFromNib()
        registerForPushNotifications()
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                guard granted else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.clientErrorDelegate = self
        
        trackConnectionStatus()
        trackUnreadCount()
        if let userId = UserDefaults.standard.userId {
            login(with: userId, displayName: nil)
        } else {
            login(with: "victimIOS", displayName: "iOS User 1")
        }

        displayNameController = DisplayNameButtonController(displayNameButton: displayNameButton,
                                                            userObject: client.currentUser!)
        unreadCountController = UnreadCountLabelController(unreadCountLabel: totalMessageCountLabel,
                                                           repository: channelRepository)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let destination as ChannelListTableViewController:
            channelListViewController = destination
            channelListViewController.delegate = self
            channelListViewController.repository = channelRepository
            channelListViewController.channelType = channelType
        case let destination as ConnectionStatusLEDViewController:
            destination.client = client
            channelListViewController.repository = channelRepository
        case let destination as MoreTableViewController:
            destination.client = client
            destination.delegate = self
        case let destination as CreateChannelTableViewController:
            destination.channelCreator = self
        default:
            break
        }
    }

    private func trackUnreadCount() {
       totalUnreadCountObservationToken = channelRepository.observe(\.totalUnreadCount) { [weak self] channelRepository, _ in
            self?.totalMessageCountLabel.text = channelRepository.totalUnreadCount.description
        }
    }

    private func trackConnectionStatus() {
        connectionStatusObservationToken = client.observe(\.connectionStatus) { [weak self] client, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                if let currentUser = client.currentUser {
                    self?.displayNameController.observe(userObject: currentUser)
                }
                self?.fireNewQuery(connectionStatus: client.connectionStatus)
            }
        }
    }

    private func fireNewQuery(connectionStatus: EkoConnectionStatus) {
        guard connectionStatus == .connected else { return }
        channelListViewController.fetchChannelList()
    }

    @IBAction private func titleTapped() {
        let titleText = "Enter Your New Display Name"
        let alertController = UIAlertController(title: titleText, message: nil, preferredStyle: .alert)

        let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let newDisplayName: String = alertController.textFields?.first?.text else { return }
            self?.client.setDisplayName(newDisplayName, completion: nil)
        }
        alertController.addAction(renameAction)

        alertController.addTextField { (textField) in
            textField.placeholder = self.client.currentUser?.object?.displayName
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    @IBAction private func profileTap() {
        let alertController = UIAlertController(title: "New login", message: nil, preferredStyle: .alert)

        alertController.addTextField(configurationHandler: { textField in
            textField.placeholder = "UserId"
        })

        let loginAction = UIAlertAction(title: "Login", style: .default, handler: { _ in
            guard let userlId = alertController.textFields?.first?.text else { return }
            self.client.unregisterDevice()
            self.login(with: userlId, displayName: nil)
        })
        alertController.addAction(loginAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: MoreTableViewControllerDelegate

    func moreTable(_ viewController: MoreTableViewController, willChangeChannelType channelType: EkoChannelType) {
        channelListViewController.channelType = channelType
        fireNewQuery(connectionStatus: client.connectionStatus)
    }
    
    // MARK: ChannelsTableViewControllerDelegate

    func joinChannel(_ channelId: String, type: EkoChannelType, isComments: Bool) {
        if isComments {
            joinComments(channelId: channelId, type: type)
        } else {
            joinChat(channelId: channelId, type: type)
        }
    }

    private func joinChat(channelId: String, type: EkoChannelType) {
        joinChat(storyboardIdentifier: "EkoChat",
                 channelId: channelId,
                 type: type)
    }

    private func joinComments(channelId: String, type: EkoChannelType) {
        joinChat(storyboardIdentifier: "EkoComments",
                 channelId: channelId,
                 type: type)
    }

    private func joinChat(storyboardIdentifier: String, channelId: String, type: EkoChannelType) {
        let storyboard = UIStoryboard(name: "Chats", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: storyboardIdentifier)
        guard let chatViewController = viewController as? EkoChatViewController else { return }
        chatViewController.channelId = channelId
        chatViewController.client = client
        chatViewController.joinChannel(channelId: channelId,
                                       type: type)
        navigationController?.pushViewController(chatViewController, animated: true)
    }

    private func login(with userId: String, displayName: String?) {
        
        Log.add(info: "Registering device. \(userId) displayName: \(String(describing: displayName))")
        client.registerDevice(withUserId: userId, displayName: displayName, authToken: nil)
        UserDefaults.standard.set(userId, forKey: "userId")
    }

    // MARK: ChannelCreator
    
    var channelCreationToken: EkoNotificationToken?
    
    func createChannel(channelId: String?, type: EkoChannelType, userIds: [String], avatar: UIImage?) {
        
        let randomId = Int.random(in: 100...9999)
        
        var channelObject: EkoObject<EkoChannel>?
        
        switch type {
        case .live:
            Log.add(info: "Creating Live channel")
            let builder = EkoLiveChannelBuilder()
            
            if let id = channelId {
                builder.setId(id)
            }
            builder.setUserIds(userIds)
            builder.setDisplayName("my-live-channel_\(randomId)")
            builder.setTags(["ch-live","ios-sdk"])
            builder.setMetadata(["sdk_type":"ios"])
            
            channelObject = channelRepository.createChannel().live(with: builder)
            
        case .community:
            Log.add(info: "Creating community channel")
            
            let builder = EkoCommunityChannelBuilder()
            
            if let id = channelId {
                builder.setId(id)
            }
            builder.setUserIds(userIds)
            builder.setDisplayName("my-community-channel_\(randomId)")
            builder.setTags(["ch-comm","ios-sdk"])
            builder.setMetadata(["sdk_type":"ios"])
            
            channelObject = channelRepository.createChannel().community(with: builder)
            
        case .conversation:
            Log.add(info: "Creating conversation channel")
            
            let builder = EkoConversationChannelBuilder()
            builder.setUserIds(userIds)
            builder.setDisplayName("my-conversation-channel_\(randomId)")
            builder.setTags(["ch-conv","ios-sdk"])
            builder.setMetadata(["sdk_type":"ios"])
            
            channelObject = channelRepository.createChannel().conversation(with: builder)
            
        default:
            Log.add(info: "Private & Standard channel types are depreciated.")
        }
        
        channelCreationToken = channelObject?.observe({ [weak self] channel, error in
            self?.channelCreationToken?.invalidate()
            
            switch channel.dataStatus {
            case .local, .fresh:
                // Channel is created, join it
                self?.joinChannel(channelId: channel.object!.channelId, channelObject: channel, type: type)
                
                // Just showing how to set avatar. You can upload the image first and set avatar data when creating channel
                if let avatar = avatar {
                    self?.channelRepository.setAvatarForChannel(channel.object!.channelId, avatar: avatar, completion: nil)
                }
                
            case .error, .notExist:
                fallthrough
                
            default:
                self?.displayOkAlert(title: "Error", message: "Error while creating channel with id \(String(describing: channelId)). Channel with same id may already exist")
            }
            
            
        })
    }
    
    private func joinChannel(channelId: String, channelObject: EkoObject<EkoChannel>, type: EkoChannelType) {
        let isCommentsChannel: Bool
        if let channel: EkoChannel = channelObject.object, let tags: [String] = channel.tags as? [String],
            tags.contains("comments") {
            isCommentsChannel = true
        } else {
            isCommentsChannel = false
        }

        joinChannel(channelId, type: type, isComments: isCommentsChannel)
    }

    // MARK: EkoClientErrorDelegate

    func didReceiveAsyncError(_ error: Error) {
        let error = error as NSError
        guard
            let ekoError = EkoErrorCode(rawValue: error.code)
            else {
                assertionFailure("unknown error \(error.code), please report this code to Eko")
                return
        }

        displayAlert(for: ekoError)
    }

    private func displayAlert(for error: EkoErrorCode) {
        displayOkAlert(title: "Eko Error", message: String(describing: error))
    }

    private func displayOkAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true)
    }
}

