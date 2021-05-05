//
//  ChannelLevelPushNotificationManager.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/14/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

final class ChannelLevelPushNotificationManager: PushNotificationsManager {
    unowned let client: AmityClient
    let channelId: String

    init(client: AmityClient, channelId: String) {
        self.client = client
        self.channelId = channelId
    }

    // MARK: PushNotificationsManager

    func fetchCurrentState(completion: @escaping (PushNotificationState) -> Void) {
        let channelRepository = AmityChannelRepository(client: client)
        let pushNotificationManager = channelRepository.notificationManagerForChannel(withId: channelId)

        pushNotificationManager.getSettings { (settings, error) in
            if let s = settings {
                completion(s.isEnabled ? .allowed : .disallowed)
            } else {
                completion(.unknown)
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
        let channelRepository = AmityChannelRepository(client: client)
        let pushNotificationManager = channelRepository.notificationManagerForChannel(withId: channelId)

        let completionHandler = { (success: Bool, error: Error?) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(success))
            }
        }
        
        if isAllowed {
            pushNotificationManager.enable(completion: completionHandler)
        } else {
            pushNotificationManager.disable(completion: completionHandler)
        }
        
    }
}
