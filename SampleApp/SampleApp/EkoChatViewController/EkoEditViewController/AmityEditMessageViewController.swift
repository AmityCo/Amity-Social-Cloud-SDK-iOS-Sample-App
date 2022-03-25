//
//  AmityEditMessageViewController.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 11/15/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import AmitySDK

private let reuseIdentifier = "SampleAppTableViewCell"

protocol AmityEditMessageViewControllerDelegate: AnyObject {
    func amityEdit(_ viewController: AmityEditMessageViewController, willUpdateText text: String, onMessage message: AmityMessage?, metadata: [String: Any]?, mentionees: AmityMentioneesBuilder?)
}

final class AmityEditMessageViewController: UIViewController {

    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var updateButton: UIButton!
    
    @IBOutlet private weak var membersTableView: UITableView!
    @IBOutlet private weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tableViewBottomContstraint: NSLayoutConstraint!
    
    private var mentionManager: AmityMentionManager?
    
    weak var delegate: AmityEditMessageViewControllerDelegate?
    
    private var message: AmityMessage?
    
    // To be injected.
    var client: AmityClient!
    
    // To be injected.
    var channelId: String!
    lazy var channelPartecipation = AmityChannelParticipation(client: client,
                                                         andChannel: channelId)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateButton.isEnabled = false
        
        textView.delegate = self
        
        let nib = UINib(nibName: "SampleAppTableViewCell", bundle: nil)
        membersTableView?.register(nib, forCellReuseIdentifier: reuseIdentifier)
        
        membersTableView?.tableFooterView = UIView()
        membersTableView.keyboardDismissMode = .none
        
        hideMentionsTableView()
        
        // Keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        channelPartecipation.startReading()
        
        setupMentionManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        channelPartecipation.stopReading()
    }
    
    private func setupMentionManager() {
        mentionManager = AmityMentionManager(withType: .message(channelId: channelId))
        mentionManager?.delegate = self

        if let metadata = message?.metadata {
            mentionManager?.setMentions(metadata: metadata, inText: message?.data?["text"] as? String ?? "")
        }
    }
    
    private func hideMentionsTableView() {
        tableViewHeightConstraint.constant = 0
        membersTableView?.isHidden = true
    }
    
    func setMessage(message: AmityMessage) {
        setText(message: message)
    }
    
    private func setText(message: AmityMessage) {
        self.message = message
    }
    
    @IBAction func handleUpdateButton(_ sender: Any) {
        let metadata = mentionManager?.getMetadata()
        let mentionees = mentionManager?.getMentionees()
        
        delegate?.amityEdit(self, willUpdateText: textView.text, onMessage: message, metadata: metadata, mentionees: mentionees)
        
        mentionManager?.resetState()
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
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (textView.text ?? "").count > AmityMentionManager.maximumCharacterCountForPost {
            showAlertForMaximumCharacters()
            return false
        }
        
        return mentionManager?.shouldChangeTextIn(textView, inRange: range, replacementText: text, currentText: textView.text ?? "") ?? true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        mentionManager?.changeSelection(textView)
    }
}

extension AmityEditMessageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mentionManager?.addMention(from: textView, in: textView.text ?? "", at: indexPath)
    }
}

extension AmityEditMessageViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mentionManager?.itemsCount ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sampleAppCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? SampleAppTableViewCell else { return UITableViewCell() }
        if let model = mentionManager?.item(at: indexPath) {
            sampleAppCell.titleLabel?.text = model.isChannel ? "@all: Notify everyone in this channel" : model.displayName
        }
        
        return sampleAppCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == (mentionManager?.itemsCount ?? 0) - 4 {
            mentionManager?.loadMore()
        }
    }
}

extension AmityEditMessageViewController {
    private func keyboardWillChange(height: CGFloat) {
        tableViewBottomContstraint.constant = height

        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded()
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardWillChange(height: keyboardSize.height)
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardWillChange(height: keyboardSize.height)
        }
    }
}

extension AmityEditMessageViewController: AmityMentionManagerDelegate {
    func didGetUsers(users: [AmityMentionUserModel]) {
        if users.isEmpty {
            tableViewHeightConstraint.constant = 0
            membersTableView.isHidden = true
        } else {
            var heightConstant:CGFloat = 240.0
            if users.count < 5 {
                heightConstant = CGFloat(users.count) * 52.0
            }
            tableViewHeightConstraint.constant = heightConstant
            membersTableView.isHidden = false
            membersTableView.reloadData()
        }
    }

    func didCreateAttributedString(attributedString: NSAttributedString) {
        textView.attributedText = attributedString
    }

    func didMentionsReachToMaximumLimit() {
        let message = "Mentions are reached to maximum limit"
        let alertController = UIAlertController(title: "Unable to mention", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Done", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    func didCharactersReachToMaximumLimit() {
        showAlertForMaximumCharacters()
    }

    private func showAlertForMaximumCharacters() {
        let title = "Unable to mention"
        let message = "Text reached to maximum characters limit"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Done", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
