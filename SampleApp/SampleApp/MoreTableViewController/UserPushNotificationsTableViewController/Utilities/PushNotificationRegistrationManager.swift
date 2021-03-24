//
//  PushNotificationRegistrationManager.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/27/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import EkoChat

final class PushNotificationRegistrationManager {
    private unowned let client: EkoClient

    init(client: EkoClient) {
        self.client = client
    }

    func register(token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        client.registerDeviceForPushNotification(withDeviceToken: token) { [weak self] success, error in
            self?.swiftify(success: success, error: error, completion: completion)
        }
    }

    func unregisterUser(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = client.currentUserId else { return }
        client.unregisterDevicePushNotification(forUserId: currentUserId) { [weak self] _, success, error in
            self?.swiftify(success: success, error: error, completion: completion)
        }
    }

    func unregisterDevice(completion: @escaping (Result<Void, Error>) -> Void) {
        client.unregisterDevicePushNotification(forUserId: nil) { [weak self] _, success, error in
            self?.swiftify(success: success, error: error, completion: completion)
        }
    }

    private func swiftify(success: Bool, error: Error?, completion: (Result<Void, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(()))
        }
    }
}
