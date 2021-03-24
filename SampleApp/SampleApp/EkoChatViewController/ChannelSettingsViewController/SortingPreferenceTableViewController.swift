//
//  SortingPreferenceTableViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 7/1/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit

class SortingPreferenceTableViewController: UITableViewController {

    // to be injected
    var channelId: String!

    private enum Section: CaseIterable {
        case reversePreferenceValue
        case reversePreferenceAction
    }

    private var reversePreference: Bool {
        get { return UserDefaults.standard.channelReversePreference[channelId] ?? true }
        set { UserDefaults.standard.channelReversePreference[channelId] = newValue }
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        switch Section.allCases[indexPath.section] {
        case .reversePreferenceAction:
            break
        case .reversePreferenceValue:
            setupReverseValueCell(cell)
        }

        return cell
    }

    private func setupReverseValueCell(_ cell: UITableViewCell) {
        let message: String

        if reversePreference {
            message = "Newest Messages first"
        } else {
            message = "Oldest messages first"
        }

        cell.textLabel?.text = message
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Section.allCases[indexPath.section] {
        case .reversePreferenceValue:
            return
        case .reversePreferenceAction:
            UserDefaults.standard.channelReversePreference[channelId] = indexPath.row != 0
            tableView.reloadData()
        }
    }
}
