//
//  ChannelSettingsTableViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/13/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit

class ChannelSettingsTableViewController: UITableViewController {
    /// To be injected.
    @objc weak var client: EkoClient!
    @objc var channelId: String!

    enum Rows: Int, CaseIterable {
        case filterTagsPreference
        case filterParentIdPreference
        case sortingPreference
        case members
        case setChannelTags
        case pushNotificationsPreference
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = Rows(rawValue: indexPath.row) else { return }
        switch row {
        case .members: navigateToMembersView()
        case .filterParentIdPreference: break // filter by parentId (done via storyboard segue)
        case .setChannelTags: navigateToTagsView()
        case .sortingPreference,
             .pushNotificationsPreference,
             .filterTagsPreference: break
        }
    }

    private func navigateToMembersView() {
        let channelMembersViewController = MembershipListTableViewController()
        channelMembersViewController.client = client
        channelMembersViewController.channelId = channelId
        show(channelMembersViewController, sender: self)
    }

    private func navigateToTagsView() {
        let channelTagsViewController = ChannelTagsTableViewController(style: .grouped)
        channelTagsViewController.client = client
        channelTagsViewController.channelId = channelId
        show(channelTagsViewController, sender: self)
    }

    // MARK: View Lifecycle

    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        switch segue.destination {
        case let pushNotificationsViewController as PushNotificationsTableViewController:
            let channelPushNotificationManager = ChannelLevelPushNotificationManager(client: client,
                                                                                     channelId: channelId)
            pushNotificationsViewController.pushNotificationManager = channelPushNotificationManager
        case let sortingPreferenceViewController as SortingPreferenceTableViewController:
            sortingPreferenceViewController.channelId = channelId
        case let tagsPreferenceViewController as FilterByTagPreferenceTableViewController:
            tagsPreferenceViewController.channelId = channelId
        case let parentIdPreferenceViewController as ParentFilterPreferenceViewController:
            parentIdPreferenceViewController.channelId = channelId
        default:
            break
        }
    }
}
