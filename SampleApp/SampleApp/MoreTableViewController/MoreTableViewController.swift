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
            // Disconnect
            client.unregisterDevice()
        default:
            break
        }
    }
    
    private func updateUserMeta() {
        let alertController = UIAlertController(title: "Update User Meta",
                                                message: "",
                                                preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Type the meta here"
        }
        let addAction = UIAlertAction(title: "Update", style: .default) { action in
            guard let meta = alertController.textFields?.first?.text, !meta.isEmpty else { return }
            let data = [
                "meta": meta
            ]
            UserUpdateManager.shared.updateMetadata(metadata: data, completion: nil)
        }
        alertController.addAction(addAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
