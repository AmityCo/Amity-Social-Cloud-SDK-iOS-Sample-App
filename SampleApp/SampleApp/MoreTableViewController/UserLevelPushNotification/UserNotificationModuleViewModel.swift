//
//  UserNotificationModuleViewModel.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 12/3/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import Foundation

struct UserNotificationModuleViewModel {

    let type: AmityNotificationModuleType
    var isEnabled: Bool
    var acceptOnlyModerator: Bool

    var title: String {
        switch type {
        case .chat:
            return "Chat Notification"
        case .social:
            return "Social Notification"
        case .videoStreaming:
            return "Video-Streaming Notification"
        @unknown default:
            fatalError()
        }
    }
}
