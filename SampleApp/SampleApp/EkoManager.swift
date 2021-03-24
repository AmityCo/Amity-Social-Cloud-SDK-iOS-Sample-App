//
//  EkoManager.swift
//  SampleApp
//
//  Created by Michael Abadi on 13/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation
import EkoChat

final class EkoManager {
    
    private(set) var client: EkoClient?
    
    static let shared: EkoManager = EkoManager()
    
    static func setClient(client: EkoClient) {
        EkoManager.shared.client = client
    }
}
