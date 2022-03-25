//
//  MembershipListTableViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/10/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import AmitySDK
import UIKit
import SwiftUI

private let reuseIdentifier = "MemberTableViewCell"

final class MembershipListTableViewController: UITableViewController, DataSourceListener {
    weak var client: AmityClient!
    var channelId: String!
    
    private var resultSearchController = UISearchController()
    private var dataSource: MembershipListDataSource!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = MembershipListDataSource(client: client, channelId: channelId)
        dataSource.dataSourceObserver = self
        let nib = UINib(nibName: "SampleAppTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        
        title = "Memberships"
        
        // remove empty rows
        tableView.tableFooterView = UIView()
        
        resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.searchBar.sizeToFit()
            
            controller.searchBar.placeholder = "ex. teacher"
            
            tableView.tableHeaderView = controller.searchBar
            
            return controller
        })()
        
        let permissionButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.right.circle"), style: .plain, target: self, action: #selector(onPermissionButtonTap))
            
        let filterButton = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3.decrease.circle"), style: .plain, target: self, action: #selector(onFilterButtonTap))
        
        self.navigationItem.rightBarButtonItems = [permissionButton, filterButton]
    }
    
    @objc func onPermissionButtonTap() {
        
        let permissionController = UIHostingController(rootView: UserPermissionView(channelId: channelId))
        self.navigationController?.pushViewController(permissionController, animated: true)
    }
    
    @objc func onFilterButtonTap() {
        
        let actionSheet = UIAlertController(title: "Choose Member Filter", message: "", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "All Members", style: .default, handler: { [weak self] action in
            self?.title = "All Members"
            self?.dataSource.updateMembershipFilter(filter: .all)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Banned Members", style: .default, handler: { [weak self] action in
            self?.title = "Banned Members"
            self?.dataSource.updateMembershipFilter(filter: .ban)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Muted Members", style: .default, handler: { [weak self] action in
            self?.title = "Muted Members"
            self?.dataSource.updateMembershipFilter(filter: .mute)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfMemberships()
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == dataSource.numberOfMemberships() - 2 {
            dataSource.fetchNext()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let membership = dataSource.membership(for: indexPath) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        guard let sampleAppCell = cell as? SampleAppTableViewCell else { return UITableViewCell() }
        
        sampleAppCell.titleLabel?.text = membership.userId
        setTags(in: sampleAppCell, for: membership)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showAvailableActionsForMember(at: indexPath)
    }
    
    private func setTags(in cell: SampleAppTableViewCell, for membership: AmityChannelMember) {
        let tags: [(text: String, color: UIColor)] = self.tags(for: membership)
        
        let mutableAttributedString = NSMutableAttributedString()
        for tag in tags {
            let attributedTagString = NSAttributedString(string: " \(tag.text) ",
                                                         attributes: [.backgroundColor: tag.color,
                                                                      .foregroundColor: .white])
            mutableAttributedString.append(attributedTagString)
            mutableAttributedString.append(NSAttributedString(string: " "))
        }
        
        cell.subtitleLabel.attributedText = mutableAttributedString
    }
    
    private func tags(for membership: AmityChannelMember) -> [(String, UIColor)] {
        let pastelColors: [UIColor] = [UIColor(named: "PastelRed"),
                                       UIColor(named: "PastelOrange"),
                                       UIColor(named: "PastelYellow"),
                                       UIColor(named: "PastelGreen"),
                                       UIColor(named: "PastelBlue"),
                                       UIColor(named: "PastelGreen"),
                                       UIColor(named: "NeonPink"),
                                       UIColor(named: "NeonRed"),
                                       UIColor(named: "NeonGreen"),
                                       UIColor(named: "NeonAzure")].compactMap { $0 }
        var tags: [(String, UIColor)] = []
        
        if membership.isBanned {
            tags.append(("Banned", pastelColors[tags.count % pastelColors.count]))
        }
        
        if membership.isMuted {
            tags.append(("Muted", pastelColors[tags.count % pastelColors.count]))
        }
        
        for role in membership.roles as? [String] ?? [] {
            tags.append((role, pastelColors[tags.count % pastelColors.count]))
        }
        
        return tags
    }
    
    // MARK: DataSourceListener
    
    func didUpdateDataSource() {
        tableView.reloadData()
    }

    func showAvailableActionsForMember(at indexPath: IndexPath) {
        guard let member = dataSource.membership(for: indexPath) else { return }
        
        let actionSheet = UIAlertController(title: "Choose Action", message: "", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Add Role", style: .default, handler: { [weak self] action in
            self?.showAlert(type: .add, for: indexPath)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Remove Role", style: .default, handler: { [weak self] action in
            self?.showAlert(type: .remove, for: indexPath)
        }))
        
        let currentUserId = AmityManager.shared.client?.currentUserId ?? ""
        if currentUserId != member.userId {
            if member.isBanned {
                actionSheet.addAction(UIAlertAction(title: "Unban", style: .default, handler: { [weak self] action in
                    self?.dataSource.unbanMember(at: indexPath, completion: { isSuccess, error in
                        let info = isSuccess ? "Unban Successful" :  "Unban Failed"
                        self?.showAlert(message: "\(info), Error: \(String(describing: error))")
                    })
                }))
            } else {
                actionSheet.addAction(UIAlertAction(title: "Ban", style: .default, handler: { [weak self] action in
                    self?.dataSource.banMember(at: indexPath, completion: { isSuccess, error in
                        let info = isSuccess ? "Ban Successful" :  "Ban Failed"
                        self?.showAlert(message: "\(info), Error: \(String(describing: error))")
                    })
                }))
            }
        }
        
        actionSheet.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
}

extension MembershipListTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        dataSource.filterMembers(by: searchController.searchBar.text)
    }
}

//MARK:- Alert for role input
private extension MembershipListTableViewController {
    func showAlert(type actionType: RoleActionType, for indexPath: IndexPath) {
        let alert = UIAlertController(title: "Role action", message: actionType.message, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Write a role"
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self, weak alert] (_) in
            guard let textField = alert?.textFields?.first, let text = textField.text, !text.isEmpty else { return }
            switch actionType {
            case .add:
                self?.dataSource.addRole(for: indexPath, role: text)
            case .remove:
                self?.dataSource.removeRole(for: indexPath, role: text)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(ok)
        present(alertController, animated: true, completion: nil)
    }
}

enum RoleActionType: Int {
    case add
    case remove
    
    var message: String {
        switch self {
        case .add: return "Add a role to the member"
        case .remove: return "Remove a role form the member"
        }
    }
}
