//
//  AmityEditMessageViewController.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 11/15/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityEditMessageViewControllerDelegate: AnyObject {
    func amityEdit(_ viewController: AmityEditMessageViewController, willUpdateText text: String, onMessage message: AmityMessage?)
}

final class AmityEditMessageViewController: UIViewController {

    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var updateButton: UIButton!
    
    weak var delegate: AmityEditMessageViewControllerDelegate?
    
    private var message: AmityMessage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateButton.isEnabled = false
        textView.text = message?.data?["text"] as? String
        textView.delegate = self
    }
    
    func setMessage(message: AmityMessage) {
        setText(message: message)
    }
    
    private func setText(message: AmityMessage) {
        self.message = message
    }
    
    @IBAction func handleUpdateButton(_ sender: Any) {
        delegate?.amityEdit(self, willUpdateText: textView.text, onMessage: message)
        navigationController?.dismiss(animated: true, completion: nil)
    }
        
    static func make() -> UIViewController {
        let sb = UIStoryboard(name: "Chats", bundle: nil)
        if #available(iOS 13.0, *) {
            return sb.instantiateViewController(identifier: "AmityEditMessageViewController")
        } else {
            // Fallback on earlier versions
            return sb.instantiateViewController(withIdentifier: "AmityEditMessageViewController")
        }
    }

}

extension AmityEditMessageViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        updateButton.isEnabled = textView.text != message?.data?["text"] as? String
    }
    
}
