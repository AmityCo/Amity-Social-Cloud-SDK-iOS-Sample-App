//
//  AmityChannelType.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/11/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import AmitySDK

extension AmityChannelType: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .standard: return "Standard"
        case .private: return "Private"
        case .byTypes: return "All (By Types)"
        case .broadcast: return "Broadcast"
        case .conversation: return "Conversation"
        case .live: return "Live"
        case .community: return "Community"
        @unknown default: return "Unknown"
        }
    }
}

extension AmityChannelCreateType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .standard: return "Standard"
        case .private: return "Private"
        @unknown default: return "Unknown"
        }
    }
}
