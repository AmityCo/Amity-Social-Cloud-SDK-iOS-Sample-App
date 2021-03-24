//
//  PushNotificationsManager.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/14/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

protocol PushNotificationsManager: AnyObject {
    func fetchCurrentState(completion: @escaping (PushNotificationState) -> Void)
    func enablePushNotifications(completion: @escaping (Result<Bool, Error>) -> Void)
    func disablePushNotifications(completion: @escaping (Result<Bool, Error>) -> Void)
}
