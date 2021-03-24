//
//  UserPostReactionsViewController.swift
//  SampleApp
//
//  Created by Nishan Niraula on 5/25/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit

class UserPostReactionsViewController: UIViewController {

    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var post: EkoPost?
    var feedManager: UserPostsFeedManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        tableView.tableFooterView = UIView()
        
        fetchAllReactionsForPost(reaction: "like")
    }
    
    @IBAction func onSegmentChange(_ sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0 {
            fetchAllReactionsForPost(reaction: "like")
        } else {
            fetchAllReactionsForPost(reaction: "love")
        }
        
        self.tableView.reloadData()
    }
    
    func fetchAllReactionsForPost(reaction: String) {
        feedManager?.observeReactionsForPost(post: post, reaction: reaction, completion: { [weak self] in
            
            self?.tableView.reloadData()
        })
    }
}

extension UserPostReactionsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(feedManager?.reactionCollection?.count() ?? 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: UITableViewCell.identifier)
        
        let reaction = feedManager?.getReactionAtIndex(index: indexPath.row)
        cell.textLabel?.text = reaction?.reactorDisplayName
        cell.detailTextLabel?.text = feedManager?.getReadableDate(date: reaction?.createdAtDate)
        
        return cell
    }
}
