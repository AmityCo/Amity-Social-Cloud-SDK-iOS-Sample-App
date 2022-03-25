//
//  MyFollowRealTimeEventController.swift
//  SampleApp
//
//  Created by Nishan Niraula on 2/9/22.
//  Copyright © 2022 David Zhang. All rights reserved.
//

import UIKit

class MyFollowRealTimeEventController: UIViewController {

    /*
    let tableView = UITableView()
    
    var manager: MyFollowRealTimeEventManager!
    var isShowingOtherUserFollower = false
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let nib = UINib(nibName: RealTimeEventHeaderCell.identifier, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: RealTimeEventHeaderCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.reloadData()
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        
        let followTypeButton = UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: self, action: #selector(onFollowTypeButtonTap))
        let queryOptionButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Filter"), style: .plain, target: self, action: #selector(onQueryOptionButtonTap))
        
        var barButtons = [UIBarButtonItem]()
        barButtons.append(followTypeButton)
        
        if !isShowingOtherUserFollower {
            barButtons.append(queryOptionButton)
        }
        
        self.navigationItem.rightBarButtonItems = [queryOptionButton, followTypeButton]
        
        manager.fetchFollowInfo { [weak self] in
            self?.tableView.reloadData()
        }
        
        fetchFollowerList()
    }
    
    @objc func onFollowTypeButtonTap() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let pendingMenu = UIAlertAction(title: "My Follower", style: .default) { [weak self] _ in
            self?.manager.isFollowerListType = true
            self?.fetchFollowerList()
        }
        
        let acceptedMenu = UIAlertAction(title: "My Following", style: .default) { [weak self]  _ in
            self?.manager.isFollowerListType = false
            self?.fetchFollowerList()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(pendingMenu)
        alertController.addAction(acceptedMenu)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func onQueryOptionButtonTap() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let pendingMenu = UIAlertAction(title: "Pending", style: .default) { [weak self] _ in
            self?.manager.followQueryOption = .pending
            self?.fetchFollowerList()
        }
        
        let acceptedMenu = UIAlertAction(title: "Accepted", style: .default) { [weak self]  _ in
            self?.manager.followQueryOption = .accepted
            self?.fetchFollowerList()
        }
        
        let allMenu = UIAlertAction(title: "All", style: .default) { [weak self]  _ in
            self?.manager.followQueryOption = .all
            self?.fetchFollowerList()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(pendingMenu)
        alertController.addAction(acceptedMenu)
        alertController.addAction(allMenu)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    func fetchFollowerList() {
        self.navigationItem.title = manager.getPageTitle()
        
        manager.fetchData { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

extension MyFollowRealTimeEventController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return manager.elements.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let element = manager.elements[section]
        return manager.getRowCount(element: element)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionElement = manager.elements[indexPath.section]
        
        switch sectionElement {
        case .header:
            let cell = tableView.dequeueReusableCell(withIdentifier: RealTimeEventHeaderCell.identifier) as! RealTimeEventHeaderCell
            cell.modelDetailLabel.numberOfLines = 0
            cell.modelDetailLabel.text = manager.getFollowInfoDescription()
            
            cell.subscribeAction = { [weak self] in
                self?.showAllFollowEvents(isSubscribeAction: true)
            }
            
            cell.unsubscribeAction = { [weak self] in
                self?.showAllFollowEvents(isSubscribeAction: false)
            }
            
            return cell
        case .follow:
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier)!
            
            let relationship = manager.followerList[indexPath.row]
            
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = manager.isFollowerListType ? relationship.followerDescription : relationship.followingDescription
            
            // Fetch next page when last item of the list is displayed.
            if indexPath.row == manager.followerList.count - 1 {
                manager.fetchNextPage()
            }

            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionElement = manager.elements[indexPath.section]
        guard sectionElement == .follow && !isShowingOtherUserFollower else { return }
        
        let info = manager.followerList[indexPath.row]
        let userId = info.targetUserId
        
        let manager = UserFollowRealTimeEventManager()
        manager.userId = userId
        
        let controller = MyFollowRealTimeEventController()
        controller.manager = manager
        controller.isShowingOtherUserFollower = true
        
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func showAllFollowEvents(isSubscribeAction: Bool) {
        var actions = [UIAlertAction]()
        let events: [AmityFollowEvent] = [.myFollowers, .myFollowing]
        
        for event in events {
            let action = UIAlertAction(title: getEventDescription(event: event), style: .default) { [weak self] action in
                
                guard let strongSelf = self else { return }
                
                if isSubscribeAction {
                    strongSelf.manager.subscribeEvent(event: event) { isSuccess in
                        let message = isSuccess ? "Subscribed Successfully" : "Failed to subscribe event"
                        AppUtility.showAlert(in: strongSelf, title: "", message: message, action: nil)
                    }
                } else {
                    strongSelf.manager.unsubscribeEvent(event: event) { isSuccess in
                        let message = isSuccess ? "Unsubscribed Successfully" : "Failed to unsubscribe event"
                        AppUtility.showAlert(in: strongSelf, title: "", message: message, action: nil)
                    }
                }
            }
            actions.append(action)
        }
        
        AppUtility.showActionSheet(in: self, title: "Events", message: isSubscribeAction ? "Subscribe events" : "Unsubscribe events", actions: actions)
    }
    
    func getEventDescription(event: AmityFollowEvent) -> String {
        switch event {
        case .myFollowers:
            return "My Followers"
        case .myFollowing:
            return "My Following"
        @unknown default:
            return ""
        }
    }
     */
}
