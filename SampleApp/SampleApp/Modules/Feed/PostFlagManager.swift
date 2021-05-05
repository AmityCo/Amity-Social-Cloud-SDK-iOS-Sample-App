//
//  PostFlagManager.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/5/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation

class PostFlagManager {
    
    let client: AmityClient = AmityManager.shared.client!
    var flagger: AmityPostFlagger?
    
    func flagPost(post: AmityPost?, completion:@escaping (_ isSuccess: Bool)->()) {
        
        guard let post = post else { return }
        
        flagger = AmityPostFlagger(client: client, postId: post.postId)
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
    
    func unflagPost(post: AmityPost?, completion:@escaping (_ isSuccess: Bool)->()) {
        
        guard let post = post else { return }
        
        flagger = AmityPostFlagger(client: client, postId: post.postId)
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
    
    func isPostFlaggedByMe(post: AmityPost?, completion:@escaping (_ isFlagged: Bool) -> ()) {
        
        guard let post = post else { return }
        
        flagger = AmityPostFlagger(client: client, postId: post.postId)
        flagger?.isPostFlaggedByMe(completion: { (isFlagged) in
            completion(isFlagged)
        })
    }
}
