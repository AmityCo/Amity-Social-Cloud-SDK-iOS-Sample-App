//
//  FollowListViewController.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 14/6/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import UIKit

enum FollowListType {
    case myFollowing(status: AmityFollowQueryOption)
    case myFollower(status: AmityFollowQueryOption)
    case userFollowing(userId: String)
    case userFollower(userId: String)
}

protocol FollowManagerDelegate: AnyObject {
    func dataDidChange()
}

class FollowManager {
    
    private let userRepo: AmityUserRepository
    private var followManager: AmityUserFollowManager {
        return userRepo.followManager
    }
    private var followCollection: AmityCollection<AmityFollowRelationship>?
    private var token: AmityNotificationToken?
    
    weak var delegate: FollowManagerDelegate?
    
    private(set) var follows: [AmityFollowRelationship] = []
    
    init() {
        userRepo = AmityUserRepository(client: AmityManager.shared.client!)
    }
    
    var type: FollowListType = .myFollower(status: .pending) {
        didSet {
            setup()
        }
    }
    
    func reloadData() {
        followManager.clearAmityFollowRelationshipLocalData()
        setup()
    }
    
    func nextPage() {
        if let followCollection = followCollection, followCollection.loadingStatus == .loaded {
            followCollection.nextPage()
        }
    }
    
    private func setup() {
        token?.invalidate()
        
        switch type {
        case .myFollowing(let status):
            followCollection = followManager.getMyFollowingList(with: status)
        case .myFollower(let status):
            followCollection = followManager.getMyFollowerList(with: status)
        case .userFollowing(let userId):
            followCollection = followManager.getUserFollowingList(withUserId: userId)
        case .userFollower(let userId):
            followCollection = followManager.getUserFollowerList(withUserId: userId)
        }
        
        token = followCollection?.observe { [weak self] (collection, _, error) in
            var follows: [AmityFollowRelationship] = []
            for i in 0..<collection.count() {
                guard let follow = collection.object(at: i) else { continue }
                follows.append(follow)
            }
            self?.follows = follows
            self?.delegate?.dataDidChange()
        }
    }
    
    func getMyFollowInfo(completion: ((Result<AmityMyFollowInfo, Error>) -> Void)?) {
        followManager.getMyFollowInfo { (success, info, error) in
            if let info = info {
                completion?(.success(info))
            } else {
                completion?(.failure(error!))
            }
        }
    }
    
    func getUserFollowInfo(userId: String, completion: ((Result<AmityUserFollowInfo, Error>) -> Void)?) {
        followManager.getUserFollowInfo(withUserId: userId) { (success, info, error) in
            if let info = info {
                completion?(.success(info))
            } else {
                completion?(.failure(error!))
            }
        }
    }
    
    func acceptUserRequest(userId: String) {
        followManager.acceptUserRequest(withUserId: userId) { (success, _, _) in
            print("-> accept \(success ? "success" : "fail")")
        }
    }
    
    func declineUserRequest(userId: String) {
        followManager.declineUserRequest(withUserId: userId) { (success, _, error) in
            print("-> decline \(success ? "success" : "fail")")
        }
        
    }
    
    func unfollowUser(userId: String) {
        followManager.unfollowUser(withUserId: userId) { (success, _, _) in
            print("-> cancel request \(success ? "success" : "fail")")
        }
    }
    
}

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
        title = pageType == .following ? "Following" : "Follower"
        
        filterButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Filter"), style: .plain, target: self, action: #selector(filterTapped))
        infoButton = UIBarButtonItem(image: #imageLiteral(resourceName: "error"), style: .plain, target: self, action: #selector(infoTapped))
        navigationItem.rightBarButtonItems = [filterButton, infoButton]
        
        manager.delegate = self
        manager.reloadData()
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
            self?.option = .pending
        }
        let acceptedMenu = UIAlertAction(title: "Accepted", style: .default) { [weak self]  (_) in
            print("Accepted")
            self?.option = .accepted
        }
        let allMenu = UIAlertAction(title: "All", style: .default) { [weak self]  (_) in
            print("All")
            self?.option = .all
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(pendingMenu)
        alertController.addAction(acceptedMenu)
        alertController.addAction(allMenu)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
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
