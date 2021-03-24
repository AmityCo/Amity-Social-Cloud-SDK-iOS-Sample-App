//
//  EkoEditMessageViewController.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 11/15/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import EkoChat

protocol EkoEditMessageViewControllerDelegate: AnyObject {
    func ekoEdit(_ viewController: EkoEditMessageViewController, willUpdateText text: String, onMessage message: EkoMessage?)
}

final class EkoEditMessageViewController: UIViewController {

    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var updateButton: UIButton!
    
    weak var delegate: EkoEditMessageViewControllerDelegate?
    
    private var message: EkoMessage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateButton.isEnabled = false
        textView.text = message?.data?["text"] as? String
        textView.delegate = self
    }
    
    func setMessage(message: EkoMessage) {
        setText(message: message)
    }
    
    private func setText(message: EkoMessage) {
        self.message = message
    }
    
    @IBAction func handleUpdateButton(_ sender: Any) {
        delegate?.ekoEdit(self, willUpdateText: textView.text, onMessage: message)
        navigationController?.dismiss(animated: true, completion: nil)
    }
        
    static func make() -> UIViewController {
        let sb = UIStoryboard(name: "Chats", bundle: nil)
        if #available(iOS 13.0, *) {
            return sb.instantiateViewController(identifier: "EkoEditMessageViewController")
        } else {
            // Fallback on earlier versions
            return sb.instantiateViewController(withIdentifier: "EkoEditMessageViewController")
        }
    }

}

extension EkoEditMessageViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        updateButton.isEnabled = textView.text != message?.data?["text"] as? String
    }
    
}
