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
        
        let permissionButton = UIBarButtonItem(title: "Permission", style: .plain, target: self, action: #selector(onPermissionButtonTap))
        self.navigationItem.rightBarButtonItems = [permissionButton]
    }
    
    @objc func onPermissionButtonTap() {
        
        let permissionController = UIHostingController(rootView: UserPermissionView(channelId: channelId))
        self.navigationController?.pushViewController(permissionController, animated: true)
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfMemberships()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let membership = dataSource.membership(for: indexPath) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        guard let sampleAppCell = cell as? SampleAppTableViewCell else { return UITableViewCell() }

        sampleAppCell.titleLabel?.text = membership.userId
        setTags(in: sampleAppCell, for: membership)
        return cell
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
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "Remove role") { [weak self] (action, view, completionHandler) in
            self?.showAlert(type: .remove, for: indexPath)
            completionHandler(true)
        }

        action.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "Add role") { [weak self] (action, view, completionHandler) in
            self?.showAlert(type: .add, for: indexPath)
            completionHandler(true)
        }

        action.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [action])
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

        self.present(alert, animated: true, completion: nil)
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
