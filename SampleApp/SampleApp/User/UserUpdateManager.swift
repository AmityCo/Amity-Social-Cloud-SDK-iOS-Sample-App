//
//  UserUpdateManager.swift
//  SampleApp
//
//  Created by Nishan Niraula on 4/8/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import Foundation

//
// Note:
// This class is a singleton for sample app purpose. This code might not represent the best practice
// and should not be copied as it is.
class UserUpdateManager {
    
    typealias UpdateCompletion = (Bool) -> Void
    
    static let shared = UserUpdateManager()
    
    private init() { }
    
    func updateMetadata(metadata: [String: Any], completion: UpdateCompletion?) {
        
        let updateBuilder = AmityUserUpdateBuilder()
        updateBuilder.setUserMetadata(metadata)
        
        performUpdateRequest(builder: updateBuilder, completion: nil)
    }
    
    func updateDescription(description: String, completion: UpdateCompletion?) {
        
        let updateBuilder = AmityUserUpdateBuilder()
        updateBuilder.setUserDescription(description)
        
        performUpdateRequest(builder: updateBuilder, completion: nil)
    }
    
    func updateDisplayName(displayName: String, completion: UpdateCompletion?) {
        
        let updateBuilder = AmityUserUpdateBuilder()
        updateBuilder.setDisplayName(displayName)
        
        performUpdateRequest(builder: updateBuilder, completion: nil)
    }
    
    func performUpdateRequest(builder: AmityUserUpdateBuilder, completion: UpdateCompletion?) {
        
        AmityManager.shared.client?.updateUser(builder, completion: { (success, error) in
            
            Log.add(info: "Error Occurred: \(String(describing: error))")
            completion?(success)
        })
    }
}

