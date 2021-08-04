//
//  CommunityFeedViewController.swift
//  SampleApp
//
//  Created by Sarawoot Khunsri on 1/7/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import UIKit
import SwiftUI

struct CommunityFeedViews: UIViewControllerRepresentable {
    var viewModel: CommunityFeedViewModel
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CommunityFeedViews>) -> CommunityFeedViewController {
        let vc = CommunityFeedViewController(viewModel: viewModel)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CommunityFeedViewController, context: UIViewControllerRepresentableContext<CommunityFeedViews>) {
        
    }
}

class CommunityFeedViewController: UIViewController {
    
    @IBOutlet private var tableView: UITableView!
    
    private let viewModel: CommunityFeedViewModel
    
    init(viewModel: CommunityFeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CommunityFeedViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "CommunityFeedTableViewCell", bundle: nil), forCellReuseIdentifier: "CommunityFeedTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        query(feedType: .published)
    }
    
    private func query(feedType: AmityFeedType) {
        viewModel.queryFeed(sort: .lastCreated, feedType: feedType, completion: { [weak self] in
            self?.tableView.reloadData()
        })
    }
    
    @IBAction func queryFeed() {
        let sheet = UIAlertController(title: "Query Feed", message: nil, preferredStyle: .actionSheet)
        let publishedFeed = UIAlertAction(title: "Query Published Feed", style: .default) { [weak self] _ in
            self?.query(feedType: .published)
        }
        
        let reviewingFeed = UIAlertAction(title: "Query Pending Feed", style: .default) { [weak self] _ in
            self?.query(feedType: .reviewing)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        sheet.addAction(publishedFeed)
        sheet.addAction(reviewingFeed)
        sheet.addAction(cancel)
        present(sheet, animated: true, completion: nil)
    }
}

extension CommunityFeedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = viewModel.post(at: indexPath)
        if viewModel.feedType == .reviewing {
            let actionSheet = UIAlertController(title: "What would you like to do?", message: nil, preferredStyle: .actionSheet)
            let approveAction = UIAlertAction(title: "Approve Post", style: .default) { [weak self] _ in
                self?.viewModel.approve(post: post, completion: { message in
                    self?.showAlert(message: message)
                })
            }
            
            let declineAction = UIAlertAction(title: "Decline Post", style: .default) { [weak self] _ in
                self?.viewModel.decline(post: post, completion: { message in
                    self?.showAlert(message: message)
                })
            }
            
            let deleteAction = UIAlertAction(title: "Delete Post", style: .default) { [weak self] _ in
                self?.viewModel.delete(post: post, completion: { message in
                    self?.showAlert(message: message)
                })
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
            actionSheet.addAction(approveAction)
            actionSheet.addAction(declineAction)
            actionSheet.addAction(deleteAction)
            actionSheet.addAction(cancelAction)
            
            present(actionSheet, animated: true, completion: nil)
        }
    }
    
    private func showAlert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(ok)
        present(alertController, animated: true, completion: nil)
    }
}

extension CommunityFeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.feed.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommunityFeedTableViewCell", for: indexPath)
        configure(for: cell, at: indexPath)
        return cell
    }
    
    private func configure(for cell: UITableViewCell, at indexPath: IndexPath) {
        let post = viewModel.post(at: indexPath)
        if let cell = cell as? CommunityFeedTableViewCell {
            cell.display(post: post)
        }
    }
}
