//
//  UserLevelPushNotificationManager.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 12/3/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import AmitySDK
import Foundation

protocol UserLevelPushNotificationManagerDelegate: AnyObject {
    func manager(_ manager: UserLevelPushNotificationManager, didReceiveNotification notification: AmityUserNotificationSettings)
    func manager(_ manager: UserLevelPushNotificationManager, didFailWithError error: Error)
}

final class UserLevelPushNotificationManager {

    unowned let client: AmityClient
    weak var delegate: UserLevelPushNotificationManagerDelegate?

    var isEnabled: Bool = false
    var modules: [UserNotificationModuleViewModel] = []

    init(client: AmityClient) {
        self.client = client
    }

    func fetchUserNotification() {
        let notificationManager = client.notificationManager
        notificationManager.getSettingsWithCompletion { [weak self] (notification, error) in
            guard let strongSelf = self,
                  let notification = notification else { return }
            strongSelf.isEnabled = notification.isEnabled
            strongSelf.modules = notification.modules.map { UserNotificationModuleViewModel(type: $0.moduleType, isEnabled: $0.isEnabled, acceptOnlyModerator: $0.roleFilter?.roleIds?.contains("moderator") ?? false ) }
            strongSelf.delegate?.manager(strongSelf, didReceiveNotification: notification)
        }
    }

    func updateNotification() {
        let notificationManager = client.notificationManager
        if isEnabled {
            let _modules = modules.map { module -> AmityUserNotificationModule in
                let roleIds: [String] = module.acceptOnlyModerator ? ["moderator"] : []
                return AmityUserNotificationModule(moduleType: module.type, isEnabled: module.isEnabled, roleFilter: .onlyFilter(withRoleIds: roleIds))
            }
            notificationManager.enable(for: _modules, completion: nil)
            notificationManager.enable(for: _modules) { [weak self] success, error in
                guard let strongSelf = self else { return }
                strongSelf.handleResponse(error: error)
            }
        } else {
            notificationManager.disable { [weak self] success, error in
                guard let strongSelf = self else { return }
                strongSelf.handleResponse(error: error)
            }
        }
    }

    private func handleResponse(error: Error?) {
        if let error = error {
            delegate?.manager(self, didFailWithError: error)
        }
        
        fetchUserNotification()
    }
}
