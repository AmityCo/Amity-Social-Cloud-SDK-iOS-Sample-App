//
//  AmityChannelSelectionViewController.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 2/7/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit

final class AmityChannelSelectionViewController: UIViewController {

    private enum ChannelType: Int {
        case standard
        case `private`
        case byTypes
        case broadcast
        case conversation
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
        
    private func presentHomeViewController(channelType: AmityChannelType) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
            viewController.channelType = channelType
            show(viewController, sender: self)
        }
    }

    @IBAction private func handleChannelType(_ sender: UIButton) {
        switch sender.tag {
        case ChannelType.standard.rawValue:
            presentHomeViewController(channelType: .standard)
        case ChannelType.private.rawValue:
            presentHomeViewController(channelType: .private)
        case ChannelType.byTypes.rawValue:
            presentHomeViewController(channelType: .unknown)
        case ChannelType.broadcast.rawValue:
            presentHomeViewController(channelType: .broadcast)
        case ChannelType.conversation.rawValue:
            presentHomeViewController(channelType: .conversation)
        default:
            break
        }
    }
}
