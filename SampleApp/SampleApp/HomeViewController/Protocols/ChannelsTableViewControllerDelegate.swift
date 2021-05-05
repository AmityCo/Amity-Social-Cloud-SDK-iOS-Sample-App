//
//  ChannelsTableViewControllerDelegate.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/7/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import Foundation

protocol ChannelsTableViewControllerDelegate: AnyObject {
    func joinChannel(_ channelId: String,
                     type: AmityChannelType,
                     isComments: Bool)
}

protocol CommentsDelegate: AnyObject {
    func seeComments(for parentId: String)
}
