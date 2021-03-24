//
//  ChannelListTableViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 10/4/18.
//  Copyright © 2018 David Zhang. All rights reserved.
//

import UIKit
import SwiftUI

/*
 * Note:
 *
 * Look into `ChannelListDataSource` class to see the sdk implementation to fetch channel
 * list.
 */
final class ChannelListTableViewController: UIViewController, DataSourceListener, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var updateButton: UIButton!
    
    // To be injected.
    var repository: EkoChannelRepository! {
        didSet {
            dataSource = ChannelListDataSource(channelRepository: repository)
            dataSource?.dataSourceObserver = self
        }
    }
    
    weak var delegate: ChannelsTableViewControllerDelegate?
    var channelType: EkoChannelType = .standard
    
    private var dataSource: ChannelListDataSource?
    private lazy var cellConfigurator = ChannelListTableViewCellConfigurator()
    
    let refreshControl = UIRefreshControl()
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: SampleAppTableViewCell.identifier, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: SampleAppTableViewCell.identifier)
        
        refreshControl.addTarget(self, action: #selector(fetchChannelList), for: .valueChanged)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        
        filterButton.addTarget(self, action: #selector(onFilterButtonTap), for: .touchUpInside)
        updateButton.addTarget(self, action: #selector(onUpdateButtonTap), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchChannelList()
    }
    
    @objc func onFilterButtonTap() {
        let hostingController = UIHostingController(rootView: ChannelFilterView())
        self.navigationController?.pushViewController(hostingController, animated: true)
    }
    
    @objc func onUpdateButtonTap() {
        let hostingController = UIHostingController(rootView: ChannelUpdateView())
        self.navigationController?.pushViewController(hostingController, animated: true)
    }
    
    /// Fires a new request to fetch all the channels matching the current filters and tags preferences.
    @objc func fetchChannelList() {
        guard let dataSource = dataSource else { return }
        let channelFilter = UserDefaults.standard.filter
        let includingTags = UserDefaults.standard.includingTags
        let excludingTags = UserDefaults.standard.excludingTags
        channelType = UserDefaults.standard.channelTypeFilter

        Log.add(info: "Channel Type: \(UserDefaults.standard.channelTypeFilter.description)")
        Log.add(info: "Filter: \(channelFilter.description)")
        Log.add(info: "Including Tags: \(includingTags), Excluding Tags: \(excludingTags)")
        
        refreshControl.endRefreshing()

        if (channelFilter == .userIsNotMember || channelFilter == .all) && channelType == .private {
            dataSource.fetchChannels(channelType: .byTypes, channelFilter: channelFilter, includingTags: includingTags, excludingTags: excludingTags, channelTypeName: Set(arrayLiteral: "private"))
        } else {
            dataSource.fetchChannels(channelType: channelType, channelFilter: channelFilter, includingTags: includingTags, excludingTags: excludingTags)
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.numberOfChannels() ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let channel: EkoChannel = dataSource?.channel(for: indexPath) else { return UITableViewCell() }
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: SampleAppTableViewCell.identifier, for: indexPath)
        guard let sampleAppCell = cell as? SampleAppTableViewCell else { return UITableViewCell() }
        
        cellConfigurator.configure(sampleAppCell, with: channel)
        return sampleAppCell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let channel: EkoChannel = dataSource?.channel(for: indexPath) else { return }
        
        self.displayActions(actions: ["Join Channel", "View Details"], title: "", message: "What would you like to do?") { [weak self] action, index in
            
            switch index {
            case 0:
                self?.join(channel: channel)
            default:
                let detailController = UIHostingController(rootView: ChannelDetailsView(detail: ChannelDetail(object: channel)))
                self?.navigationController?.pushViewController(detailController, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let channelId = dataSource?.channel(for: indexPath)?.channelId ?? ""
        let action1 = UIContextualAction(style: .normal, title: "Copy Id") { (action, view, completion) in
            UIPasteboard.general.string = channelId
            completion(true)
        }
        
        let config = UISwipeActionsConfiguration(actions: [action1])
        return config
    }
    
    /// Joins the given channel.
    private func join(channel: EkoChannel) {
        let isComments: Bool = self.isComments(channel: channel)
        delegate?.joinChannel(channel.channelId, type: .standard, isComments: isComments)
    }
    
    /// Detects wheter the channel is a comments channel or not.
    private func isComments(channel: EkoChannel) -> Bool {
        if let tags = channel.tags as? [String], tags.contains("comments") {
            return true
        } else {
            return false
        }
    }
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        if distanceFromBottom < height {
            dataSource?.fetchMoreChannels()
        }
    }
    
    // MARK: DataSourceListener
    
    func didUpdateDataSource() {
        tableView.reloadData()
    }
}

extension EkoChannelQueryFilter: CustomStringConvertible {
    public var description: String {
        switch self {
        case .all: return "All"
        case .userIsMember: return "User Is Member"
        case .userIsNotMember: return "User Is Not A Member"
        @unknown default:
            assertionFailure("Unknown")
            return "Unknown"
        }
    }
}

extension UIViewController {
    
    func displayActions(actions: [String], title: String, message: String, selectedAction: @escaping (String, Int) -> Void) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        for (index, action) in actions.enumerated() {
            let sheetAction = UIAlertAction(title: action, style: .default) { _ in
                selectedAction(action, index)
            }
            alertController.addAction(sheetAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
