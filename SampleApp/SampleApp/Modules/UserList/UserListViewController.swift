//
//  UserListViewController.swift
//  SampleApp
//
//  Created by Nishan Niraula on 5/11/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit

class UserListViewController: UIViewController, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var listManager: UserListManager!
    var userRepository: AmityUserRepository!
    var followManager: AmityUserFollowManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listManager = UserListManager(client: AmityManager.shared.client!)
        userRepository = AmityUserRepository(client: AmityManager.shared.client!)
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchAllUsetList()
    }
    
    func updateUserList() {
        self.tableView.reloadData()
    }
    
    func setupViews() {
        self.title = "Users"
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
        tableView.keyboardDismissMode = .onDrag
        
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search user name"
        searchBar.delegate = self
        
        let addDescriptionButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addDescription))
        self.navigationItem.rightBarButtonItem = addDescriptionButton
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        listManager.searchUserList(name: searchText) { [weak self] in
            self?.updateUserList()
        }
    }
    
    func fetchAllUsetList() {
        listManager.fetchUserList(sortedBy: .displayName) { [weak self] in
            self?.updateUserList()
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let frameHeight = scrollView.frame.size.height
        let contentOffset = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        let distanceFromBottom = contentHeight - contentOffset
        if distanceFromBottom < frameHeight {
            listManager.loadMoreUsers()
        }
    }
    
    func displayUserFeed(userId: String, userName: String?) {
        let feedManager = UserPostsFeedManager(client: AmityManager.shared.client!, userId: userId, userName: userName)
        feedManager.feedType = .userFeed
        
        let postsFeedStoryboard = UIStoryboard(name: "Feed", bundle: nil)
        let postsFeedController = postsFeedStoryboard.instantiateViewController(withIdentifier: UserPostsFeedViewController.identifier) as! UserPostsFeedViewController
        postsFeedController.feedManager = feedManager
        
        self.navigationController?.pushViewController(postsFeedController, animated: true)
    }
    
    @objc func addDescription() {
        UIAlertController.showAlertForUserInput(in: self, title: "User", message: "Set user description:") { description in
            UserUpdateManager.shared.updateDescription(description: description, completion: nil)
        }
    }
}

extension UserListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listManager.numberOfUsers()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: UserListTableViewCell.identifier) as! UserListTableViewCell
        
        let user = listManager.getUserItem(at: indexPath.row)
        cell.delegate = self
        cell.userNameLabel.text = user?.displayName ?? "-"
        cell.userIdLabel.text = "Id: \(user?.userId ?? "")"
        cell.avatarLabel.text = "Avatar: Id: \(user?.avatarFileId ?? ""), URL: \(user?.avatarCustomUrl ?? "")"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = listManager.getUserItem(at: indexPath.row) else { return }
        displayUserFeed(userId: user.userId, userName: user.displayName)
    }
}

enum FollowAction: String {
    case follow
    case unfollow
    case accept
    case decline
}

extension UserListViewController: UserListTableViewCellDelegate {
    
    func cellOptionDidTap(_ cell: UserListTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              let userId = listManager.getUserItem(at: indexPath.row)?.userId else { return }
        followManager = userRepository.followManager
        
        
        let completion: (FollowAction, Bool, AmityFollowResponse?, Error?) -> Void = { [weak self] (action, success, response, error) in
            var title = ""
            var message = ""
            if success {
                title = "\(action.rawValue.capitalized) successfully"
            } else {
                title = "Failed"
                message = "You are not able to \(action.rawValue) this user"
            }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            self?.present(alert, animated: true, completion: nil)
        }
        
        let alertController = UIAlertController(title: "Actions", message: title, preferredStyle: .actionSheet)
        
        followManager.getUserFollowInfo(withUserId: userId) { [weak self] (success, info, error) in
            guard let info = info else { return }
            
            let followAction = UIAlertAction(title: "Follow", style: .default) { [weak self] _ in
                self?.followManager.followUser(withUserId: userId) {
                    completion(.follow, $0, $1, $2)
                }
            }
            let unfollowAction = UIAlertAction(title: "Unfollow", style: .default) { [weak self] _ in
                self?.followManager.unfollowUser(withUserId: userId) {
                    completion(.unfollow, $0, $1, $2)
                }
            }
            let acceptRequestAction = UIAlertAction(title: "Accept Request", style: .default) { [weak self] _ in
                self?.followManager.acceptUserRequest(withUserId: userId) {
                    completion(.accept, $0, $1, $2)
                }
            }
            let declineRequestAction = UIAlertAction(title: "Decline Request", style: .default) { [weak self] _ in
                self?.followManager.declineUserRequest(withUserId: userId) {
                    completion(.decline, $0, $1, $2)
                }
            }
            switch info.status {
            case .none:
                alertController.addAction(followAction)
            case .accepted:
                alertController.addAction(unfollowAction) // unfollow
            case .pending:
                alertController.addAction(unfollowAction) // withdraw request
            @unknown default: break
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            self?.present(alertController, animated: true, completion: nil)
        }
        
    }
    
}

extension UIAlertController {
    
    class func showAlertForUserInput(in vc: UIViewController, title: String, message: String, action: ((_ input: String) -> Void)?) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: { textField in
            textField.placeholder = "Input"
        })

        let inputAction = UIAlertAction(title: "Submit", style: .default, handler: { _ in
            guard let userInput = alertController.textFields?.first?.text else { return }
            action?(userInput)
        })
        alertController.addAction(inputAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        vc.present(alertController, animated: true, completion: nil)
    }
}
