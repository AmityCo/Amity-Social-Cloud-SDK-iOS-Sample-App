//
//  AmityManager.swift
//  SampleApp
//
//  Created by Michael Abadi on 13/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation
import AmitySDK

/*
 Shared instance used for convenience in this Sample App.
 
 We recommend having a single instance of AmityClient for your whole app. You can share it using
 singleton or use dependency injection as per your usecase
 */
final class AmityManager {
    
    private(set) var client: AmityClient?
    
    /// An array storing json stirng of push payload, sorted in ascending order.
    private(set) var pushPayloads: [String] = []
    
    var postRepository: AmityPostRepository?
    
    static let shared: AmityManager = AmityManager()
    
    // Production Environment
    // Note:
    // If you want to use default region, you can also use `AmityClient(apiKey: _)` method.
    func setup(apiKey: String, region: AmityRegion) {
        guard !apiKey.isEmpty else {
            assertionFailure("Api key is required!")
            return
        }
        
        Log.add(info: "AmityClient setup with production environment")
        self.client = try? AmityClient(apiKey: apiKey, region: region)
        
        setupRepositories()
    }
    
    // Custom environment
    func setup(environment: ApiEnvironment) {
        let endpoint = AmityEndpoint(httpUrl: environment.httpUrl, rpcUrl: environment.rpcUrl, mqttHost: environment.mqttHost)
        
        Log.add(info: "AmityClient setup with custom environment \(environment.description)")
        self.client = try? AmityClient(apiKey: environment.apiKey, endpoint: endpoint)
        
        setupRepositories()
    }
    
    func setupRepositories() {
        guard let client = client else {
            assertionFailure("Client must not be nil at this point.")
            return
        }
        
        postRepository = AmityPostRepository(client: client)
    }
    
    func appendNotificationPayload(_ userInfo: [AnyHashable: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: userInfo, options: [.prettyPrinted])
            let json = String(data: data, encoding: .utf8)
            pushPayloads.append(json ?? "Unable to convert to json string.")
        } catch {
            Log.add(info: "Unable to convert notification payload to json string.")
        }
    }
    
}
