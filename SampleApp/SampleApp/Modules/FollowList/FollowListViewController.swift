//
//  FollowListViewController.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 14/6/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import UIKit
import AmitySDK

enum FollowListPageType {
    case following
    case follower
}

class FollowListViewController: UIViewController {
    
    let manager = FollowManager()
    
    var follows: [AmityFollowRelationship] {
        return manager.follows
    }
    
    var pageType: FollowListPageType = .following {
        didSet {
            updateStatus()
        }
    }
    var option: AmityFollowQueryOption = .pending{
        didSet {
            updateStatus()
        }
    }
    
    var userId: String?
    
    private func updateStatus() {
        if let userId = userId {
            // other user
            switch pageType {
            case .following:
                manager.type = .userFollowing(userId: userId)
            case .follower:
                manager.type = .userFollower(userId: userId)
            }
            
            navigationItem.rightBarButtonItem = nil
        } else {
            // current user
            switch (pageType, option) {
            case (.following, _):
                manager.type = .myFollowing(status: option)
            case (.follower, _):
                manager.type = .myFollower(status: option)
            }
        }
    }

    @IBOutlet weak var tableView: UITableView!
    private var filterButton: UIBarButtonItem!
    private var infoButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        setPageTitle()
        
        filterButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Filter"), style: .plain, target: self, action: #selector(filterTapped))
        infoButton = UIBarButtonItem(image: #imageLiteral(resourceName: "error"), style: .plain, target: self, action: #selector(infoTapped))
        navigationItem.rightBarButtonItems = [filterButton, infoButton]
        
        manager.delegate = self
        self.fetchList(option: .pending)
    }
    
    @objc func infoTapped() {
        manager.getMyFollowInfo() { [weak self] (result) in
            switch result {
            case .success(let info):
                let message = "Following: \(info.followingCount) | Follower: \(info.followersCount) | Pending: \(info.pendingCount)"
                let alertController = UIAlertController(title: "Follow Info", message: message, preferredStyle: .alert)
                let cancel = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(cancel)
                self?.present(alertController, animated: true, completion: nil)
                
                break
            case .failure:
                break
            }
        }
    }
    
    @objc func filterTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let pendingMenu = UIAlertAction(title: "Pending", style: .default) { [weak self] (_) in
            print("Pending")
            self?.fetchList(option: .pending)
        }
        let acceptedMenu = UIAlertAction(title: "Accepted", style: .default) { [weak self]  (_) in
            print("Accepted")
            self?.fetchList(option: .accepted)
        }
        let allMenu = UIAlertAction(title: "All", style: .default) { [weak self]  (_) in
            self?.fetchList(option: .all)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(pendingMenu)
        alertController.addAction(acceptedMenu)
        alertController.addAction(allMenu)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    func fetchList(option: AmityFollowQueryOption) {
        self.option = option
        self.setPageTitle()
        self.manager.reloadData()
    }
    
    func setPageTitle() {
        let optionTitle = self.option.title
        title = pageType == .following ? "Following (\(optionTitle))" : "Follower (\(optionTitle))"
    }
}

extension FollowListViewController: FollowManagerDelegate {
    func dataDidChange() {
        tableView.reloadData()
    }
}

extension FollowListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return follows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: FollowListTableViewCell.identifier) as! FollowListTableViewCell
        let follow = follows[indexPath.row]
        cell.delegate = self
        
        switch pageType {
        case .following:
            cell.userNameLabel.text = follow.targetUser?.displayName ?? "-"
            cell.userIdLabel.text = "Id: \(follow.targetUserId)"
            cell.avatarLabel.text = "Status: \(follow.status.title)"
        case .follower:
            cell.userNameLabel.text = follow.sourceUser?.displayName ?? "-"
            cell.userIdLabel.text = "Id: \(follow.sourceUserId)"
            cell.avatarLabel.text = "Status: \(follow.status.title)"
        }
        
        switch (manager.type, follow.status) {
        case (.myFollowing, .pending):
            // cancel request
            cell.configure(with: [.cancel])
            break
        case (.myFollowing, .accepted):
            // unfollow
            cell.configure(with: [.unfollow])
            break
        case (.myFollower, .pending):
            // accept / decline
            cell.configure(with: [.accept, .decline])
            break
        case (.myFollower, .accepted):
            // remove follower
            cell.configure(with: [.remove])
            break
        default: break
        }
        
        // Load next page, when showing the last item in the collection.
        if indexPath.row == manager.follows.count - 1 {
            manager.nextPage()
        }
        
        return cell
    }
    
}

extension FollowListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userId = pageType == .following ? follows[indexPath.row].targetUserId : follows[indexPath.row].sourceUserId
        let followInfoController = UIStoryboard(name: "Feed", bundle: nil).instantiateViewController(withIdentifier: FollowInfoViewController.identifier) as! FollowInfoViewController
        followInfoController.userId = userId
        navigationController?.pushViewController(followInfoController, animated: true)
    }
    
}

extension FollowListViewController: FollowListTableViewCellDelegate {
    
    func actionButtonDidTap(_ cell: FollowListTableViewCell, action: FollowListActionType) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        switch action {
        case .accept:
            let targetUserId = follows[indexPath.row].sourceUserId
            manager.acceptUserRequest(userId: targetUserId)
        case .decline:
            let targetUserId = follows[indexPath.row].sourceUserId
            manager.declineUserRequest(userId: targetUserId)
        case .unfollow:
            let targetUserId = follows[indexPath.row].targetUserId
            manager.unfollowUser(userId: targetUserId)
        case .cancel:
            let targetUserId = follows[indexPath.row].targetUserId
            manager.unfollowUser(userId: targetUserId)
        case .remove:
            let targetUserId = follows[indexPath.row].sourceUserId
            manager.declineUserRequest(userId: targetUserId)
        }
    }
    
}

extension AmityFollowStatus {
    var title: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .none:
            return "None"
        @unknown default:
            return "-"
        }
    }
}

extension AmityFollowQueryOption {
    var title: String {
        switch self {
        case .all:
            return "All"
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        }
    }
}
