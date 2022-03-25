//
//  FollowInfoViewController.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 15/6/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import UIKit

class FollowInfoViewController: UIViewController {

    @IBOutlet weak var displaynameLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followerLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var follows: [AmityFollowRelationship] {
        return manager.follows
    }
    
    var pageType: FollowListPageType = .following
    let manager = FollowManager()
    var userId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displaynameLabel.text = userId
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        
        manager.delegate = self
        manager.getUserFollowInfo(userId: userId) { [weak self] (result) in
            switch result {
            case .success(let info):
                self?.followingLabel.text = "Following: \(info.followingCount)"
                self?.followerLabel.text = "Follower: \(info.followersCount)"
                break
            case .failure:
                self?.followingLabel.text = "Following: \(0)"
                self?.followerLabel.text = "Follower: \(0)"
                break
            }
        }
        manager.type = .userFollowing(userId: userId)
        manager.reloadData()
    }
    
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            manager.type = .userFollowing(userId: userId)
            pageType = .following
        } else {
            manager.type = .userFollower(userId: userId)
            pageType = .follower
        }
    }
}

extension FollowInfoViewController: FollowManagerDelegate {
    func dataDidChange() {
        tableView.reloadData()
    }
}

extension FollowInfoViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return follows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let follow = follows[indexPath.row]
        
        switch pageType {
        case .following:
            cell.textLabel?.text = follow.targetUser?.displayName ?? "-"
            cell.detailTextLabel?.text = "Id: \(follow.targetUserId)"
        case .follower:
            cell.textLabel?.text = follow.sourceUser?.displayName ?? "-"
            cell.detailTextLabel?.text = "Id: \(follow.sourceUserId)"
        }
        
        // Load next page, when showing the last item in the collection.
        if indexPath.row == manager.follows.count - 1 {
            manager.nextPage()
        }
        
        return cell
    }
    
}
