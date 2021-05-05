//
//  AmityReactionsViewController.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 12/24/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit

struct ReactionModel {
    let reaction: String
    let user: String
}

final class AmityReactionsViewController: UIViewController,
                                        UITableViewDelegate,
                                        UITableViewDataSource,
                                        DataSourceListener {
    
    private enum ReactionSourceType {
        case all
        case onlyMe
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    private var datasource: ReactionDatasource?
    private var myReactionsSource: [ReactionModel] = []
    
    private var reactionsType: ReactionSourceType = .onlyMe
    
    private var userRepo: AmityUserRepository?
    private var userToken: Set<AmityNotificationToken> = Set()
    
    private var reversePreference: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        datasource?.dataSourceObserver = self
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancelButton))
    }
    
    @objc func handleCancelButton() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func setDatasource(_ source: ReactionDatasource, userRepo: AmityUserRepository) {
        self.datasource = source
        self.userRepo = userRepo
        self.reactionsType = .all
    }
    
    func setMyReactions(_ source: [ReactionModel]) {
        self.myReactionsSource = source
    }
    
    func didUpdateDataSource() {
        for item in userToken {
            item.invalidate()
        }
        userToken.removeAll()
        tableView.reloadData()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ReactionViewCell", bundle: nil), forCellReuseIdentifier: "ReactionViewCell")
    }
    
    static func makeViewController() -> UIViewController {
        let sb = UIStoryboard(name: "Chats", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "AmityReactionsViewController")
        return vc
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if reactionsType == .all {
            return datasource?.numberOfReactions() ?? 0
        } else {
            return myReactionsSource.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "ReactionViewCell", for: indexPath)
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if reactionsType == .all {
            guard let reaction = reaction(for: indexPath) else { return }
            let cell = cell as? ReactionViewCell
            cell?.setTitle(reaction: reaction.reactionName, user: reaction.reactorDisplayName)
        } else {
            let reaction = myReactionsSource[indexPath.row]
            let cell = cell as? ReactionViewCell
            cell?.setTitle(reaction: reaction.reaction, user: reaction.user)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        switch reversePreference {
        case false:
            // load next page when scrolled to the bottom
            if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) {
                datasource?.loadMore()
            }
        case true:
            // load previous page when scrolled to the top
            if scrollView.contentOffset.y.isLessThanOrEqualTo(0) {
                datasource?.loadMore()
            }
        }
    }
    
    private func reaction(for indexPath: IndexPath) -> AmityReaction? {
        return datasource?.reaction(for: indexPath)
    }
    
}
