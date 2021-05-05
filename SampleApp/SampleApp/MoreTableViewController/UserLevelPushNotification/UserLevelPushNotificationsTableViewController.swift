//
//  CommunityPushNotificationTableViewController.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 11/3/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import AmitySDK
import UIKit

final class UserLevelPushNotificationsTableViewController: UITableViewController {
    /// To be injected.
    weak var client: AmityClient!

    lazy var manager: UserLevelPushNotificationManager = {
        let manager = UserLevelPushNotificationManager(client: self.client)
        manager.delegate = self
        return manager
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        manager.fetchUserNotification()
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return manager.modules.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell") as! SwitchTableViewCell
            cell.configure(title: "Notification", isEnabled: manager.isEnabled)
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationModuleTableViewCell") as! NotificationModuleTableViewCell
            
            let module = manager.modules[indexPath.row]
            cell.configure(title: module.title, isEnabled: module.isEnabled, isModerator: module.acceptOnlyModerator)
            cell.delegate = self
            return cell
        }
    }

    // MARK: UITableViewDelegate

    private func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default))

        present(alertController, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 44 : 80
    }

    private func registerPushTap() {
        guard let token = fetchToken() else {
            Log.add(info: "🛑 No token")
            return
        }

//        pushNotificationManager.register(token: token) { [weak self] result in
//            let title: String
//            let message: String
//            switch result {
//            case .success:
//                title = "Success 🥳"
//                message = "From now on you will receive notifications"
//            case .failure(let error):
//                title = "Failure 😵"
//                message = "Error: \(error.localizedDescription)"
//            }
//            self?.presentAlert(title: title, message: message)
//        }
    }

    private func fetchToken() -> String? {
        #if targetEnvironment(simulator)
        Log.add(info: "ℹ️ Running on simulator, mocking token")
        return "ababa" // any hex string will do
        #else
        return UserDefaults.standard.deviceToken
        #endif
    }

    private func unregisterDevicePushTap() {
//        pushNotificationManager.unregisterDevice { [weak self] result in
//            let title: String
//            let message: String
//            switch result {
//            case .success:
//                title = "Success 😶"
//                message = "You will no longer receive push notifications for this device"
//            case .failure(let error):
//                title = "📣 Failure 📣"
//                message = "Error: \(error.localizedDescription)"
//            }
//            self?.presentAlert(title: title, message: message)
//        }
    }

    private func unregisterPushTap() {
//        pushNotificationManager.unregisterUser { [weak self] result in
//            let title: String
//            let message: String
//            switch result {
//            case .success:
//                title = "Success 😶"
//                message = "You will no longer receive push notifications for this user"
//            case .failure(let error):
//                title = "📣 Failure 📣"
//                message = "Error: \(error.localizedDescription)"
//            }
//            self?.presentAlert(title: title, message: message)
//        }
    }
}

extension UserLevelPushNotificationsTableViewController: UserLevelPushNotificationManagerDelegate {
    
    func manager(_ manager: UserLevelPushNotificationManager, didReceiveNotification notification: AmityUserNotificationSettings) {
        print(notification)
        tableView.reloadData()
    }
    
}

extension UserLevelPushNotificationsTableViewController: NotificationModuleTableViewCellDelegate {
    
    func cellRoleButtonDidTap(_ cell: NotificationModuleTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        var updatedModule = manager.modules[indexPath.row]
        updatedModule.acceptOnlyModerator = cell.acceptOnlyModerator
        manager.modules[indexPath.row] = updatedModule
        manager.updateNotification()
    }
    
    func cell(_ cell: NotificationModuleTableViewCell, valueDidChange isEnabled: Bool) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        var updatedModule = manager.modules[indexPath.row]
        updatedModule.isEnabled = isEnabled
        manager.modules[indexPath.row] = updatedModule
        manager.updateNotification()
    }
    
}

extension UserLevelPushNotificationsTableViewController: SwitchTableViewCellDelegate {
    
    func cell(_ cell: SwitchTableViewCell, valueDidChange isEnabled: Bool) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        manager.isEnabled = isEnabled
        manager.updateNotification()
    }
    
}
