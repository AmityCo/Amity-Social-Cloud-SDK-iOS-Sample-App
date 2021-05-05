//
//  DisplayNameButtonController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/7/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import Foundation

/// Updates the given `UIButton` `titleLabel` based on the given `AmityUser`
final class DisplayNameButtonController {
    private unowned let displayNameButton: UIButton
    private var token: AmityNotificationToken?

    init(displayNameButton: UIButton, userObject: AmityObject<AmityUser>) {
        self.displayNameButton = displayNameButton
    }

    /// Injects the `AmityUser` to observe for `displayName` changes.
    ///
    /// - note: This method must be called everytime a new user session starts.
    ///     This is because the `AmityUser` instance is replaced after logging in/out,
    ///     therefore observing an old `AmityUser` object won't get any event regarding
    ///     the new logged-in `AmityUser` object.
    /// - Parameter userObject: The user to observe
    func observe(userObject: AmityObject<AmityUser>?) {
        token = userObject?.observe { [weak self] userObject, _ in
            guard let user: AmityUser = userObject.object else { return }
            self?.updateTitle(with: user)
        }
    }

    private func updateTitle(with user: AmityUser) {
        let titleText = title(displayName: user.displayName, userId: user.userId)
        displayNameButton.setTitle(titleText, for: .normal)
    }

    private func title(displayName: String?, userId: String) -> String {
        let escapedDisplayName: String? = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)

        if
            let escapedDisplayName = escapedDisplayName,
            !escapedDisplayName.isEmpty {
            return escapedDisplayName
        }
        return "@\(userId)"
    }
}
