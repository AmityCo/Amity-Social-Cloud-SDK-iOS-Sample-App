//
//  UserLevelPushNotificationManager.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/14/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

final class UserLevelPushNotificationManager: PushNotificationsManager {
    unowned let client: EkoClient

    init(client: EkoClient) {
        self.client = client
    }

    // MARK: PushNotificationsManager

    func fetchCurrentState(completion: @escaping (PushNotificationState) -> Void) {
        let pushNotificationManager = client.notificationManager

        pushNotificationManager.isAllowed { isAllowed, error in
            if let error = error {
                Log.add(info: "🛑 error: \(error.localizedDescription)")
                completion(.unknown)
            } else {
                completion(isAllowed ? .allowed : .disallowed)
            }
        }
    }

    func enablePushNotifications(completion: @escaping (Result<Bool, Error>) -> Void) {
        setIsAllowed(true, completion: completion)
    }

    func disablePushNotifications(completion: @escaping (Result<Bool, Error>) -> Void) {
        setIsAllowed(false, completion: completion)
    }

    private func setIsAllowed(_ isAllowed: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        let pushNotificationManager = client.notificationManager

        pushNotificationManager.setIsAllowed(isAllowed) { success, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(success))
            }
        }
    }
}
