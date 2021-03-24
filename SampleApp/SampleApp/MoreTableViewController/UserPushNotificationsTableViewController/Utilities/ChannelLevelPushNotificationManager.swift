//
//  ChannelLevelPushNotificationManager.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/14/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

final class ChannelLevelPushNotificationManager: PushNotificationsManager {
    unowned let client: EkoClient
    let channelId: String

    init(client: EkoClient, channelId: String) {
        self.client = client
        self.channelId = channelId
    }

    // MARK: PushNotificationsManager

    func fetchCurrentState(completion: @escaping (PushNotificationState) -> Void) {
        let channelRepository = EkoChannelRepository(client: client)
        let pushNotificationManager = channelRepository.notificationManager(forChannelId: channelId)

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
        let channelRepository = EkoChannelRepository(client: client)
        let pushNotificationManager = channelRepository.notificationManager(forChannelId: channelId)

        pushNotificationManager.setIsAllowed(isAllowed) { success, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(success))
            }
        }
    }
}
