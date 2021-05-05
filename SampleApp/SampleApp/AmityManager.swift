//
//  AmityManager.swift
//  SampleApp
//
//  Created by Michael Abadi on 13/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation
import AmitySDK

final class AmityManager {
    
    private(set) var client: AmityClient?
    
    static let shared: AmityManager = AmityManager()
    
    static func setClient(client: AmityClient) {
        AmityManager.shared.client = client
    }
}
