//
//  PushNotificationsTableViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/13/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit

final class PushNotificationsTableViewController: UITableViewController {
    // to be injected
    var pushNotificationManager: PushNotificationsManager!

    private var pushNotificationState: PushNotificationState = .unknown {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchCurrentState()
    }

    private func fetchCurrentState() {
        pushNotificationManager.fetchCurrentState { [weak self] state in
            self?.pushNotificationState = state
        }
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        if
            indexPath.row == 0,
            indexPath.section == 0 {
            cell.textLabel?.text = pushNotificationState.description
        }
        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }

        guard indexPath.section == 1 else { return }

        switch indexPath.row {
        case 0: enablePushNotifications()
        case 1: disablePushNotifications()
        default: assertionFailure("🛑 don't know what \(indexPath) is, please update \(#file)")
        }
    }

    private func enablePushNotifications() {
        pushNotificationManager.enablePushNotifications { [weak self] result in
            switch result {
            case .failure(let error):
                let alert = UIAlertController(title: "Something went wrong", message: error.localizedDescription, preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                alert.addAction(action)
                self?.present(alert, animated: false)
            case .success:
                self?.fetchCurrentState()
            }
        }
    }

    private func disablePushNotifications() {
        pushNotificationManager.disablePushNotifications { [weak self] _ in
            self?.fetchCurrentState()
        }
    }
}
