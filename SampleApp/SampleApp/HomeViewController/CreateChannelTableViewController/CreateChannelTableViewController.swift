//
//  CreateChannelTableViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/19/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import EkoChat

protocol ChannelCreator: AnyObject {
    func createChannel(channelId: String?, type: EkoChannelType, userIds: [String], avatar: UIImage?)
}

protocol ChannelRepositoryDelegate: AnyObject {
    func createChannel(channelId: String, type: EkoChannelCreateType, userIds: [String], avatar: UIImage?)
    func createConversation(userId: String, avatar: UIImage?)
}

final class CreateChannelTableViewController: UITableViewController, UITextFieldDelegate {
    
    weak var channelCreator: ChannelCreator?
    
    private let channelTypes: [EkoChannelType] = [.conversation, .live, .community]
    
    private var channelIdTextFieldObserver: NSKeyValueObservation?
    private var userIdTextFieldObserver: [NSKeyValueObservation?] = []
    
    private var channelId: String? = ""
    private var userIds: [String] = []
    private var selectedChannelType: EkoChannelType = .standard
    private var selectedImage: UIImage?
    private let imagePicker = UIKitImagePicker()
    
    private enum Section: CaseIterable {
        case channelId
        case type
        case userIds
        case addUserId
        case addImage
        
        var title: String? {
            switch self {
            case .channelId:
                return "Channel Id"
            case .type:
                return "Channel Type"
            case .userIds:
                return "User Ids"
            case .addImage:
                return "Add Avatar"
            case .addUserId:
                return nil
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.tableView.keyboardDismissMode = .onDrag
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .channelId:
            return 1
        case .type:
            return channelTypes.count
        case .userIds:
            return userIds.count
        case .addUserId:
            return 1
        case .addImage:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section.allCases[section].title
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let section: Section = Section.allCases[section]
        switch section {
        case .userIds:
            return "Swipe left to remove a userId."
        case .addUserId, .channelId, .type, .addImage:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section.allCases[indexPath.section] {
        case .channelId:
            return self.tableView(tableView, channelIdcellForRowAt: indexPath)
        case .type:
            return self.tableView(tableView, typeCellForRowAt: indexPath)
        case .userIds:
            return self.tableView(tableView, userIdCellForRowAt: indexPath)
        case .addUserId:
            return self.tableView(tableView, addUserIdCellForRowAt: indexPath)
        case .addImage:
            return self.tableView(tableView, addAvatarCellForRowAt: indexPath)
        }
    }
    
    private func tableView(_ tableView: UITableView, channelIdcellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.textInputCellIdentifier, for: indexPath)
        
        guard let textInputCell = cell as? TextInputTableViewCell else {
            return cell
        }
        
        let textField: UITextField = textInputCell.textField
        textField.delegate = self
        
        textInputCell.textField.placeholder = "channelId"
        textInputCell.textField.text = channelId
        channelIdTextFieldObserver = textField.observe(\.text, options: [.new, .old], changeHandler: { [weak self] (textField, _) in
            self?.channelId = textField.text
        })
        
        return textInputCell
    }
    
    private func tableView(_ tableView: UITableView, typeCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.checkmarkCellIdentifier, for: indexPath)
        
        let channelType = channelTypes[indexPath.row]
        cell.textLabel?.text = channelType.description
        cell.accessoryType = channelType == selectedChannelType ? .checkmark : .none
        
        return cell
    }
    
    private func tableView(_ tableView: UITableView, userIdCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.textInputCellIdentifier, for: indexPath)
        guard let textInputCell = cell as? TextInputTableViewCell else {
            return cell
        }
        
        let textField: UITextField = textInputCell.textField
        textField.delegate = self
        
        textField.placeholder = "userId"
        let userId = userIds[indexPath.row]
        textField.text = userId
        userIdTextFieldObserver[indexPath.row] = textField.observe(\.text, options: [.new, .old]) { [weak self] textField, _ in
            let newUserlId: String = textField.text ?? ""
            self?.userIds[indexPath.row] = newUserlId
        }
        
        return textInputCell
    }
    
    private func tableView(_ tableView: UITableView, addUserIdCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.buttonCellIdentifier, for: indexPath)
        cell.textLabel?.text = "Add userId"
        return cell
    }
    
    private func tableView(_ tableView: UITableView, addAvatarCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.imageCellIdentifier, for: indexPath)
        cell.textLabel?.text = self.selectedImage == nil ? "Upload avatar" : "Image Selected"
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        
        let section: Section = Section.allCases[indexPath.section]
        
        switch section {
        case .addUserId:
            if selectedChannelType == .conversation && userIds.count >= 1 {
                return
            }
            
            userIds.append("")
            userIdTextFieldObserver.append(nil)
            
            guard let userIdsIndex = Section.allCases.firstIndex(of: .userIds) else { return }
            tableView.reloadSections([userIdsIndex], with: .automatic)
        case .type:
            
            selectedChannelType = channelTypes[indexPath.row]
            tableView.reloadSections([indexPath.section], with: .automatic)
        case .addImage:
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            
            imagePicker.displayImagePicker(in: self, anchorView: cell) { [weak self] image in
                self?.selectedImage = image
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        default:
            break // nothing to do
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section: Section = Section.allCases[indexPath.section]
        return section == .userIds
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        userIds.remove(at: indexPath.row)
        userIdTextFieldObserver.remove(at: indexPath.row)
        guard let userIdsIndex = Section.allCases.firstIndex(of: .userIds) else { return }
        tableView.reloadSections([userIdsIndex], with: .automatic)
    }
    
    @IBAction private func createTap(_ sender: UIBarButtonItem) {
        // Make sure that the keyboard is dismissed:
        // this is needed to register all the textField(s) values in the view.
        view.endEditing(true)
        
        channelCreator?.createChannel(channelId: channelId, type: selectedChannelType, userIds: userIds, avatar: self.selectedImage)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension CreateChannelTableViewController {
    
    struct CellIdentifier {
        static let checkmarkCellIdentifier: String = "checkCell"
        static let textInputCellIdentifier: String = "textInputCell"
        static let buttonCellIdentifier: String = "buttonCell"
        static let imageCellIdentifier: String = "avatarCell"
    }
}
