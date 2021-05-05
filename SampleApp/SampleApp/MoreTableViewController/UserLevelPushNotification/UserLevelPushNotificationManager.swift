//
//  UserLevelPushNotificationManager.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 12/3/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import AmitySDK

protocol UserLevelPushNotificationManagerDelegate: class {
    func manager(_ manager: UserLevelPushNotificationManager, didReceiveNotification notification: AmityUserNotificationSettings)
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
        } else {
            notificationManager.disable(completion: nil)
        }
    }

}
