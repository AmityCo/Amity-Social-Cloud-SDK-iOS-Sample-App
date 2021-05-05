//
//  FlagManager.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/14/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import AmitySDK

final class FlagManager {
    private let client: AmityClient
    private unowned let viewController: UIViewController

    init(client: AmityClient, viewController: UIViewController) {
        self.client = client
        self.viewController = viewController
    }

    func displayFlagAlertController(for message: AmityMessage) {
        guard let user: AmityUser = message.user else { return }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let flagGroup = DispatchGroup()

            // retrieving user info
            var userFlagged: Bool = false
            flagGroup.enter()

            DispatchQueue.main.async {
                guard let client = self?.client else { return }
                let userFlagger: AmityUserFlagger = .init(client: client, user: user)
                userFlagger.isFlaggedByMe(completion: { isFlagByMe in
                    userFlagged = isFlagByMe
                    flagGroup.leave()
                })
            }

            // retrieving message info
            var messageFlagged: Bool = false
            flagGroup.enter()
            DispatchQueue.main.async {
                guard let client = self?.client else { return }
                let messageFlagger: AmityMessageFlagger = .init(client: client, message: message)
                messageFlagger.isFlaggedByMe(completion: { isFlagByMe in
                    messageFlagged = isFlagByMe
                    flagGroup.leave()
                })
            }

            // Wait until everything is done.
            flagGroup.wait()

            DispatchQueue.main.async {
                self?.displayFlagAlertControlle(message: message,
                                                user: user,
                                                userIsFlagged: userFlagged,
                                                messageIsFlagged: messageFlagged)
            }
        }
    }

    private func displayFlagAlertControlle(message: AmityMessage,
                                           user: AmityUser,
                                           userIsFlagged: Bool,
                                           messageIsFlagged: Bool) {
        let alertController = UIAlertController(title: "Actions", message: nil, preferredStyle: .alert)
        let flagMessageAction = createFlagAction(message: message, flagged: messageIsFlagged)
        let flagUserAction = createFlagAction(user: user, flagged: userIsFlagged)

        let defaultAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(flagMessageAction)
        alertController.addAction(flagUserAction)
        alertController.addAction(defaultAction)

        viewController.present(alertController, animated: true, completion: nil)
    }

    /**
     creates a @p UIAlertAction for un/flagging the given message

     @param message the message to un/flag
     @return the @p UITableViewRowAction
     */
    func createFlagAction(message: AmityMessage, flagged: Bool) -> UIAlertAction {
        let title: String = flagTitleForMessage(flagged: flagged)
        let flagMessage = UIAlertAction(title: title, style: .default, handler: { [weak self] _ in
            self?.flagAction(message: message, flagged: flagged)
        })
        return flagMessage
    }

    /**
     creates a @p UIAlertAction for un/flagging the given user

     @param user the user to un/flag
     @return the @p UITableViewRowAction
     */
    private func createFlagAction(user: AmityUser, flagged: Bool) -> UIAlertAction {
        let title: String = flagTitleForUser(flagged: flagged)

        let flagMessage = UIAlertAction(title: title, style: .default, handler: { [weak self] _ in
            self?.flagAction(user: user, flagged: flagged)
        })
        return flagMessage
    }

    /**
     returns the un/flag title for the given message

     @param flagged whether the message is flagged as of now
     @return the action title
     */
    func flagTitleForMessage(flagged: Bool) -> String {
        return flagged ? "Unflag Message" : "Flag Message"
    }

    /**
     returns the un/flag title for the given user

     @param flagged whether the message is flagged as of now
     @return the action title
     */
    private func flagTitleForUser(flagged: Bool) -> String {
        return flagged ? "Unflag User" : "Flag User"
    }

    /**
     Displays a simple UIAlertController with the given title, subtitle and an ok button, no actions are taken

     @param title the alert controller title
     @param subtitle the given subtitle
     */
    private func displayAlertController(title: String, subtitle: String?) {
        let alertController = UIAlertController.init(title: title, message: subtitle, preferredStyle: .alert)

        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)

        alertController.addAction(defaultAction)
        viewController.present(alertController, animated: true, completion: nil)
    }

    /**
     Handles the un/flag callback

     @param success the callback success parameter
     @param error the callback error parameter
     @param object a description of the object (e.g. "User" or "Message")
     @param isFlag whether this black is handling a flag callback or an unflag one
     */
    private func handleFlagBlock(success: Bool, error: Error?, object: String, isFlag: Bool) {
        if success {
            let title: String = String.init(format: "%@ %@flagged ✅", object, isFlag ? "" : "un")
            displayAlertController(title: title, subtitle: nil)
        } else {
            let title = "Error ❗️"
            displayAlertController(title: title, subtitle: error?.localizedDescription)
        }
    }

    /**
     called when the user wants to un/flag the given message:
     this method will execute the action and display a @p UIAlertController with the outcome

     @param message the message to un/flag
     */
    private func flagAction(message: AmityMessage, flagged: Bool) {
        let messageFlagger = AmityMessageFlagger(client: client, message: message)

        if flagged {
            messageFlagger.unflag { success, error in
                self.handleFlagBlock(success: success, error: error, object: "message", isFlag: false)
                // hack to keep the flagger instance alive until the completion block is called
                Log.add(info: messageFlagger)
            }
        } else {
            messageFlagger.flag { (success, error) in
                self.handleFlagBlock(success: success, error: error, object: "message", isFlag: true)
                // hack to keep the flagger instance alive until the completion block is called
                Log.add(info: messageFlagger)
            }

        }
    }

    /**
     called when the user wants to un/flag the given user:
     this method will execute the action and display a @p UIAlertController with the outcome

     @param user the user to un/flag
     */
    private func flagAction(user: AmityUser, flagged: Bool) {
        let userFlagger = AmityUserFlagger(client: client, user: user)

        if flagged {
            userFlagger.unflag { success, error in
                self.handleFlagBlock(success: success, error: error, object: "User", isFlag: false)
                // hack to keep the flagger instance alive until the completion block is called
                Log.add(info: userFlagger)
            }
        } else {
            userFlagger.flag { (success, error) in
                self.handleFlagBlock(success: success, error: error, object: "User", isFlag: true)
                // hack to keep the flagger instance alive until the completion block is called
                Log.add(info: userFlagger)
            }
        }
    }
}
