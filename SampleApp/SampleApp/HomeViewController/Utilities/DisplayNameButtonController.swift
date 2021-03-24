//
//  DisplayNameButtonController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/7/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import Foundation

/// Updates the given `UIButton` `titleLabel` based on the given `EkoUser`
final class DisplayNameButtonController {
    private unowned let displayNameButton: UIButton
    private var token: EkoNotificationToken?

    init(displayNameButton: UIButton, userObject: EkoObject<EkoUser>) {
        self.displayNameButton = displayNameButton
    }

    /// Injects the `EkoUser` to observe for `displayName` changes.
    ///
    /// - note: This method must be called everytime a new user session starts.
    ///     This is because the `EkoUser` instance is replaced after logging in/out,
    ///     therefore observing an old `EkoUser` object won't get any event regarding
    ///     the new logged-in `EkoUser` object.
    /// - Parameter userObject: The user to observe
    func observe(userObject: EkoObject<EkoUser>?) {
        token = userObject?.observe { [weak self] userObject, _ in
            guard let user: EkoUser = userObject.object else { return }
            self?.updateTitle(with: user)
        }
    }

    private func updateTitle(with user: EkoUser) {
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
