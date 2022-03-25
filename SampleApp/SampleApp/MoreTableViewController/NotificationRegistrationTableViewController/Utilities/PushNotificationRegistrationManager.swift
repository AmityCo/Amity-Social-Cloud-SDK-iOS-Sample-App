//
//  PushNotificationRegistrationManager.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/27/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import AmitySDK

final class PushNotificationRegistrationManager {
    private unowned let client: AmityClient

    init(client: AmityClient) {
        self.client = client
    }

    func register(token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        UserDefaults.standard.isRegisterdForPushNotification = true
        client.registerDeviceForPushNotification(withDeviceToken: token) { success, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func unregisterUser(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = client.currentUserId else { return }
        client.unregisterDeviceForPushNotification(forUserId: currentUserId) { (success, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func unregisterDevice(completion: @escaping (Result<Void, Error>) -> Void) {
        UserDefaults.standard.isRegisterdForPushNotification = false
        client.unregisterDeviceForPushNotification(forUserId: nil) { (success, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
