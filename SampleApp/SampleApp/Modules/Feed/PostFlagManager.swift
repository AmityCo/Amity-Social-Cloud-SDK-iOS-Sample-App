//
//  PostFlagManager.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/5/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation

class PostFlagManager {
    
    let client: EkoClient = EkoManager.shared.client!
    var flagger: EkoPostFlagger?
    
    func flagPost(post: EkoPost?, completion:@escaping (_ isSuccess: Bool)->()) {
        
        guard let post = post else { return }
        
        flagger = EkoPostFlagger(client: client, postId: post.postId)
        flagger?.flagPost(completion: { (isSuccess, error) in
            
            if let err = error {
                Log.add(info: "Flagging Error: \(err)")
                completion(false)
                return
            }
            
            Log.add(info: "Post flagged successfully")
            completion(isSuccess)
        })
    }
    
    func unflagPost(post: EkoPost?, completion:@escaping (_ isSuccess: Bool)->()) {
        
        guard let post = post else { return }
        
        flagger = EkoPostFlagger(client: client, postId: post.postId)
        flagger?.unflagPost(completion: { (isSuccess, error) in
            
            if let err = error {
                Log.add(info: "UnFlagging Error: \(err)")
                completion(false)
                return
            }
            
            Log.add(info: "Post Unflagged Successfully")
            completion(isSuccess)
        })
    }
    
    func isPostFlaggedByMe(post: EkoPost?, completion:@escaping (_ isFlagged: Bool) -> ()) {
        
        guard let post = post else { return }
        
        flagger = EkoPostFlagger(client: client, postId: post.postId)
        flagger?.isPostFlaggedByMe(completion: { (isFlagged) in
            completion(isFlagged)
        })
    }
}
