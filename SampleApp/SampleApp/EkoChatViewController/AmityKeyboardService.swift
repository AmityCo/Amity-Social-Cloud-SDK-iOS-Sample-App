//
//  AmityKeyboardService.swift
//  SampleApp
//
//  Created by Federico Zanetello on 9/17/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import Foundation

protocol KeyboardServiceDelegate: AnyObject {
    func keyboardWillAppear(service: KeyboardService)
    func keyboardWillDismiss(service: KeyboardService)
    func keyboardWillChange(service: KeyboardService,
                            height: CGFloat,
                            animationDuration: TimeInterval)
}

extension KeyboardServiceDelegate {
    func keyboardWillAppear(service: KeyboardService) {}
    func keyboardWillDismiss(service: KeyboardService) {}
    func keyboardWillChange(service: KeyboardService,
                            newHeight: CGFloat,
                            oldHeight: CGFloat,
                            animationDuration: TimeInterval) {}
}

final class KeyboardService: NSObject {
    static var shared: KeyboardService = KeyboardService()

    private override init() {
        super.init()
        subscribeToKeyboardEvents()
    }

    weak var delegate: KeyboardServiceDelegate?

    func subscribeToKeyboardEvents() {
        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self,
                                       selector: #selector(keyboardWillShow(_:)),
                                       name: UIResponder.keyboardWillShowNotification,
                                       object: nil)

        notificationCenter.addObserver(self,
                                       selector: #selector(keyboardWillHide(_:)),
                                       name: UIResponder.keyboardWillHideNotification,
                                       object: nil)
    }

    @objc
    private func keyboardWillShow(_ notification: NSNotification) {
        delegate?.keyboardWillAppear(service: self)

        if
            let userInfo: [AnyHashable: Any] = notification.userInfo,
            let durationAny: Any = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey],
            let duration: TimeInterval = durationAny as? TimeInterval,
            let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardSize.size.height
            delegate?.keyboardWillChange(service: self,
                                         height: keyboardHeight,
                                         animationDuration: duration)
        }
    }

    @objc
    private func keyboardWillHide(_ notification: NSNotification) {
        delegate?.keyboardWillDismiss(service: self)

        let duration: TimeInterval
        if
            let userInfo: [AnyHashable: Any] = notification.userInfo,
            let durationAny: Any = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey],
            let timeInterval: TimeInterval = durationAny as? TimeInterval {
            duration = timeInterval
        } else {
            duration = 0
        }
        delegate?.keyboardWillChange(service: self,
                                     height: 0,
                                     animationDuration: duration)
    }
}
