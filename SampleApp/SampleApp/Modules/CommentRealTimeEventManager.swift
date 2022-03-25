//
//  CommentRealTimeEventManager.swift
//  SampleApp
//
//  Created by Nishan Niraula on 11/24/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import Foundation

class CommentRealTimeEventManager {
    
    enum Element {
        case header
    }
    
    let comment: AmityComment
    var elements = [Element]()
    
    let commentRepo = AmityCommentRepository(client: AmityManager.shared.client!)
    var commentToken: AmityNotificationToken?
    
    init(comment: AmityComment) {
        self.comment = comment
        self.elements = [.header]
    }
    
    func getRowCount(element: Element) -> Int {
        switch element {
        case .header:
            return 1
        }
    }
    
    func subscribeEvent(event: AmityCommentEvent, completion: ((Bool) -> Void)?) {
        self.comment.subscribeEvent(event) { isSuccess, error in
            completion?(isSuccess)
            Log.add(info: "User Subscribe Event: \(isSuccess) Error: \(String(describing: error))")
        }
    }
    
    func unsubscribeEvent(event: AmityCommentEvent, completion: ((Bool) -> Void)?) {
        self.comment.unsubscribeEvent(event) { isSuccess, error in
            completion?(isSuccess)
            Log.add(info: "User unsubscribe Event: \(isSuccess) Error: \(String(describing: error))")
        }
    }

}
