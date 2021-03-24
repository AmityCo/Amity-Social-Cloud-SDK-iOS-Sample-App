//
//  EkoAddReactionsViewController.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 12/23/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit

protocol EkoAddReactionsDelegate: AnyObject {
    func didSendReaction(_ viewController: EkoAddReactionsViewController, withReactionName reaction: String, message: EkoMessage?)
    func didRemoveReaction(_ viewController: EkoAddReactionsViewController, withReactionName reaction: String, message: EkoMessage?)
}

final class EkoAddReactionsViewController: UIViewController {
    
    enum ReactionType {
        case add
        case remove
    }
    
    @IBOutlet weak var reactionTextField: UITextField!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    weak var delegate: EkoAddReactionsDelegate?
    
    private var type: ReactionType = .add
    private var message: EkoMessage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switch type {
        case .add:
            actionButton.setTitle("Add Reaction", for: .normal)
            titleLabel.text = "Add Reaction"
        case .remove:
            actionButton.setTitle("Remove Reaction", for: .normal)
            titleLabel.text = "Remove Reaction"
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancelButton))
    }
    
    @objc func handleCancelButton() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func setupView(type: ReactionType, message: EkoMessage?) {
        self.type = type
        self.message = message
    }
    
    static func makeViewController() -> UIViewController {
        let sb = UIStoryboard(name: "Chats", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "EkoAddReactionsViewController")
        return vc
    }

    @IBAction private func handleButton(_ sender: Any) {
        guard let text = reactionTextField.text else { return }
        switch type {
        case .add:
            delegate?.didSendReaction(self, withReactionName: text, message: message)
        case .remove:
            delegate?.didRemoveReaction(self, withReactionName: text, message: message)
        }
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
