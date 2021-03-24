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
    func moreTable(_ viewController: MoreTableViewController, willChangeChannelType channelType: EkoChannelType)
}

final class MoreTableViewController: UITableViewController {
    /// To be injected.
    weak var client: EkoClient!
    weak var delegate: MoreTableViewControllerDelegate?

    private var channelRepository: EkoChannelRepository?
    
    private var createToken: EkoNotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.destination {
        case let userPushNotificationsTableViewController as UserPushNotificationsTableViewController:
            userPushNotificationsTableViewController.client = client
        case let pushNotificationsViewController as PushNotificationsTableViewController:
            let userPushNotificationManager = UserLevelPushNotificationManager(client: client)
            pushNotificationsViewController.pushNotificationManager = userPushNotificationManager
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
        let addAction = UIAlertAction(title: "Update",
                                      style: .default) { [weak self] _ in
                                        guard
                                            let meta = alertController
                                                .textFields?
                                                .first?
                                                .text,
                                            !meta.isEmpty else { return }
                                        let data = [
                                            "meta": meta
                                        ]
                                        self?.client.setUserMetadata(data, completion: nil)
        }
        alertController.addAction(addAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
