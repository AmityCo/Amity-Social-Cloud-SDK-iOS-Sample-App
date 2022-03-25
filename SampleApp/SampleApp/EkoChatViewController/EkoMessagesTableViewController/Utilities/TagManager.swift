//
//  TagManager.swift
//  SampleApp
//
//  Created by Federico Zanetello on 7/30/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import AmitySDK

final class TagManager {
    private let client: AmityClient
    private unowned let viewController: UIViewController

    init(client: AmityClient, viewController: UIViewController) {
        self.client = client
        self.viewController = viewController
    }

    func displayTagAlertController(for message: AmityMessage) {
        let alertController = UIAlertController(title: "Set tags", message: "Comma separated", preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.placeholder = "a, b, c"
            if let tags = message.tags as? [String] {
                textField.text = tags.joined(separator: ", ")
            }
        }

        let messageId: String = message.messageId

        let setAction = UIAlertAction(title: "Set", style: .default) { [weak self] _ in
            guard let tagsString: String = alertController.textFields?.first?.text else { return }
            let tags: [String] = tagsString.components(separatedBy: ", ")
            self?.setTags(tags, to: messageId)
        }
        alertController.addAction(setAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        viewController.present(alertController, animated: true, completion: nil)
    }

    private func setTags(_ tags: [String], to messageId: String) {
        let messageEditor = AmityMessageEditor(client: client, messageId: messageId)
        messageEditor.setTags(tags, completion: nil)
    }
}
