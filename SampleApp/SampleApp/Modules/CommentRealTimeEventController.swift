//
//  CommentRealTimeEventController.swift
//  SampleApp
//
//  Created by Nishan Niraula on 11/24/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import UIKit

class CommentRealTimeEventController: UIViewController {
    
    let tableView = UITableView()
    
    var manager: CommentRealTimeEventManager!
    
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
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        tableView.reloadData()
    }
    
    func showAllCommentEvents(isSubscribeAction: Bool) {
        var actions = [UIAlertAction]()
        
        let events: [AmityCommentEvent] = [.comment]
        for event in events {
            let action = UIAlertAction(title: getEventDescription(event: event), style: .default) { [weak self] action in
                guard let strongSelf = self else { return }
                
                if isSubscribeAction {
                    self?.manager.subscribeEvent(event: event, completion: { isSuccess in
                        let message = isSuccess ? "Subscribed Successfully" : "Failed to subscribe event"
                        AppUtility.showAlert(in: strongSelf, title: "", message: message, action: nil)
                    })
                } else {
                    self?.manager.unsubscribeEvent(event: event, completion: { isSuccess in
                        let message = isSuccess ? "Unsubscribed Successfully" : "Failed to unsubscribe event"
                        AppUtility.showAlert(in: strongSelf, title: "", message: message, action: nil)
                    })
                }
            }
            actions.append(action)
        }
        
        AppUtility.showActionSheet(in: self, title: "Events", message: "Subscribe to events", actions: actions)
    }
    
    func getEventDescription(event: AmityCommentEvent) -> String {
        switch event {
        case .comment:
            return "Comments"
        default:
            return ""
        }
    }
}

extension CommentRealTimeEventController: UITableViewDataSource, UITableViewDelegate {
    
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
            cell.modelDetailLabel.text = manager.comment.modelDescription
            
            cell.subscribeAction = { [weak self] in
                self?.showAllCommentEvents(isSubscribeAction: true)
            }
            cell.unsubscribeAction = { [weak self] in
                self?.showAllCommentEvents(isSubscribeAction: false)
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
