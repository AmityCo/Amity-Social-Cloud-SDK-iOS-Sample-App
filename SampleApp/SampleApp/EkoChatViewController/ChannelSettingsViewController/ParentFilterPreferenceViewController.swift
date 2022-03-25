//
//  ParentFilterPreferenceViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 8/6/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit

final class ParentFilterPreferenceViewController: UITableViewController {
    // to be injected.
    var channelId: String!

    // MARK: - Table view data source

    private var active: Bool {
        get { return UserDefaults.standard.channelPreferenceFilterByParentIdActive[channelId] ?? false }
        set { UserDefaults.standard.channelPreferenceFilterByParentIdActive[channelId] = newValue }
    }

    private var parentId: String? {
        get { return UserDefaults.standard.channelPreferenceFilterByParentId[channelId] }
        set { UserDefaults.standard.channelPreferenceFilterByParentId[channelId] = newValue }
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = super.tableView(tableView, cellForRowAt: indexPath)

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            setupStatusCell(cell)
        default:
            break
        }

        return cell
    }

    private enum FilterByParentIdState: CustomStringConvertible {
        case noFilter
        case orphansOnly
        case parentMessage(messageId: String)

        // MARK: CustomStringConvertible

        var description: String {
            switch self {
            case .noFilter:
                return "no filter (receive all messages)"
            case .orphansOnly:
                return "only orphans (a.k.a. messages with no parentId)"
            case .parentMessage(messageId: let messageId):
                return "only childs of message \(messageId)"
            }
        }
    }

    private func setupStatusCell(_ cell: UITableViewCell) {
        let state: FilterByParentIdState = filterByParentIdState()
        setupStatusCell(cell, for: state)
    }

    private func filterByParentIdState() -> FilterByParentIdState {
        // According to EkoEngineering Specifications:
        // With two parameters, we have four possible scenarios:
        // - `filterByParentId` is set to `false`:
        //   query for all messages, disregard the `parentId` parameter (two scenarios).
        // - `filterByParentId` is set to `true`, no `parentId` is passed:
        //   query for all messages without a parent
        // - `filterByParentId` is set to `true`, a `parentId` is passed:
        //   query for all messages with the `parentId` as parent
        switch (active, parentId) {
        case (false, _):
            return .noFilter
        case (true, nil):
            return .orphansOnly
        case (true, let .some(parentId)):
            return .parentMessage(messageId: parentId)
        }
    }

    private func setupStatusCell(_ cell: UITableViewCell,
                                 for state: FilterByParentIdState) {
        let text = String(describing: state)
        cell.textLabel?.text = text
    }

    // MARK: - Table view data delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }

        switch (indexPath.section, indexPath.row) {
        case (1, 0): // Only Orphans
            setPreference(.orphansOnly)
        case (1, 1): // No filters
            setPreference(.noFilter)
        default:
            break
        }
        tableView.reloadData()
    }

    private func setPreference(_ state: FilterByParentIdState) {
        switch state {
        case .noFilter:
            active = false
            parentId = nil
        case .orphansOnly:
            active = true
            parentId = nil
        case .parentMessage(let messageId):
            active = true
            parentId = messageId
        }
    }
}
