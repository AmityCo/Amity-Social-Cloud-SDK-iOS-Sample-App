//
//  UserPushNotificationsTableViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/6/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

final class UserPushNotificationsTableViewController: UITableViewController {
    /// To be injected.
    weak var client: EkoClient!

    lazy var pushNotificationManager = PushNotificationRegistrationManager(client: self.client)

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        if indexPath.section == 1 {
            cell.textLabel?.text = UserDefaults.standard.deviceToken ?? "none"
        }

        return cell
    }

    // MARK: UITableViewDelegate

    private func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default))

        present(alertController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }

        switch indexPath.row {
        case 0: registerPushTap()
        case 1: unregisterPushTap()
        case 2: unregisterDevicePushTap()
        default:
            break
        }
    }

    private func registerPushTap() {
        guard let token = fetchToken() else {
            Log.add(info: "🛑 No token")
            return
        }

        pushNotificationManager.register(token: token) { [weak self] result in
            let title: String
            let message: String
            switch result {
            case .success:
                title = "Success 🥳"
                message = "From now on you will receive notifications"
            case .failure(let error):
                title = "Failure 😵"
                message = "Error: \(error.localizedDescription)"
            }
            self?.presentAlert(title: title, message: message)
        }
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
        pushNotificationManager.unregisterDevice { [weak self] result in
            let title: String
            let message: String
            switch result {
            case .success:
                title = "Success 😶"
                message = "You will no longer receive push notifications for this device"
            case .failure(let error):
                title = "📣 Failure 📣"
                message = "Error: \(error.localizedDescription)"
            }
            self?.presentAlert(title: title, message: message)
        }
    }

    private func unregisterPushTap() {
        pushNotificationManager.unregisterUser { [weak self] result in
            let title: String
            let message: String
            switch result {
            case .success:
                title = "Success 😶"
                message = "You will no longer receive push notifications for this user"
            case .failure(let error):
                title = "📣 Failure 📣"
                message = "Error: \(error.localizedDescription)"
            }
            self?.presentAlert(title: title, message: message)
        }
    }
}
