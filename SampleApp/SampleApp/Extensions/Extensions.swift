//
//  Extensions.swift
//  SampleApp
//
//  Created by Michael Abadi on 13/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation
import AmitySDK

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}

extension AmityDataStatus {
    
    var description: String {
        switch self {
        case .local:
            return "Local"
        case .error:
            return "Error"
        case .fresh:
            return "Fresh"
        case .notExist:
            return "Not Exists"
        default:
            return "Unknown"
        }
    }
    
}

extension AmitySyncState {
    
    var description: String {
        switch self {
        case .default:
            return "Default"
        case .error:
            return "Error"
        case .synced:
            return "Synced"
        case .syncing:
            return "Syncing"
        default:
            return "Unknown"
        }
    }
}

extension AmityMediaSize {
    
    var description: String {
        switch self {
        case .full:
            return "Full"
        case .large:
            return "Large"
        case .medium:
            return "Medium"
        case .small:
            return "Small"
        default:
            return "Not Available"
        }
    }
    
}
