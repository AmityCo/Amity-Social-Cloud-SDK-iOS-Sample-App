//
//  MoreTableViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/6/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import Foundation
import SwiftUI

protocol MoreTableViewControllerDelegate: AnyObject {
    func moreTable(_ viewController: MoreTableViewController, willChangeChannelType channelType: AmityChannelType)
}

final class MoreTableViewController: UITableViewController {
    /// To be injected.
    weak var client: AmityClient!
    weak var delegate: MoreTableViewControllerDelegate?

    lazy var pushNotificationManager = PushNotificationRegistrationManager(client: self.client)
    
    private var channelRepository: AmityChannelRepository?
    
    private var createToken: AmityNotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.destination {
        case let userPushNotificationsViewController as UserLevelPushNotificationsTableViewController:
            userPushNotificationsViewController.client = client
        case let notificationRegistrationTableViewController as NotificationRegistrationTableViewController:
            notificationRegistrationTableViewController.client = client
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section,indexPath.row) {
        case (2,0):
            // Update metadata
            updateUserMeta()
            
        case (2, 1):
            // Unregister
            pushNotificationManager.unregisterUser { _ in
            }
            
            pushNotificationManager.unregisterDevice { _ in
            }
            
            // Disconnect
            client.logout()
            
            showAlert(title: "Logout Successful", message: "Session is now disconnected. Everything related to this user should be cleared.")
            
        case (2,2):
            
            showInputAlert(title: "Login New User", message: "This will login new user without calling unregister for previous user", placeholder: "Enter User Id:") { [weak self] userId in
                guard let weakSelf = self else { return }
                
                weakSelf.client.login(userId: userId, displayName: nil, authToken: nil) { success, error in
                    
                    let message = success ? "Login Successful" : "Login Failed: \(String(describing: error))"
                    weakSelf.showAlert(title: "Login Response", message: message)
                }
            }
            
        case (2,3):
            client.disconnect()
            showAlert(title: "Disconnected", message: "SDK disconnects from the server without logging out the user.")
        default:
            break
        }
    }
    
    private func updateUserMeta() {
        showInputAlert(title: "Update user meta", message: "", placeholder: "Type meta here") { meta in
            
            let data = [
                "meta": meta
            ]
            UserUpdateManager.shared.updateMetadata(metadata: data, completion: nil)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func showInputAlert(title: String, message: String, placeholder: String, completion: @escaping (_ input: String) -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = placeholder
        }
        
        let addAction = UIAlertAction(title: "Submit", style: .default) { action in
            guard let meta = alertController.textFields?.first?.text, !meta.isEmpty else { return }
            completion(meta)
        }
        
        alertController.addAction(addAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
}
