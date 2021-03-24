//
//  PushNotificationState.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/14/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import Foundation

enum PushNotificationState: CustomStringConvertible {
    /// Enabled, will receive notifications (As long as the User notification state is also enabled).
    case allowed

    /// Channel is muted.
    case disallowed

    /// Current state unknown.
    case unknown

    // MARK: CustomStringConvertible

    var description: String {
        switch self {
        case .allowed: return "Allowed"
        case .disallowed: return "Disallowed"
        case .unknown: return "Unknown"
        }
    }
}
