//
//  FilterByTagPreferenceTableViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 10/29/18.
//  Copyright © 2018 David Zhang. All rights reserved.
//

import UIKit
import EkoChat

private let reuseTagIdentifier = "channelTagCell"
private let addTagIdentifier = "AddTagTableViewCell"

final class FilterByTagPreferenceTableViewController: UITableViewController {
    // to be injected.
    var channelId: String!

    enum FilterTableSection: CaseIterable {
        case includingTags, excludingTags
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "AddTagTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: addTagIdentifier)
    }

    // MARK: - Table view data source

    private var includingTags: [String] {
        get { return UserDefaults.standard.channelPreferenceIncludingTags[channelId] ?? [] }
        set { UserDefaults.standard.channelPreferenceIncludingTags[channelId] = newValue }
    }

    private var excludingTags: [String] {
        get { return UserDefaults.standard.channelPreferenceExcludingTags[channelId] ?? [] }
        set { UserDefaults.standard.channelPreferenceExcludingTags[channelId] = newValue }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return FilterTableSection.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch FilterTableSection.allCases[section] {
        case .includingTags:
            return "Including Tags:"
        case .excludingTags:
            return "Excluding Tags:"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch FilterTableSection.allCases[section] {
        case .includingTags,
             .excludingTags:
            return "Swipe left to remove a tag."
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch FilterTableSection.allCases[section] {
        case .includingTags:
            return includingTags.count + 1 // tags + last cell is used for adding more tags
        case .excludingTags:
            return excludingTags.count + 1 // tags + last cell is used for adding more tags
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch FilterTableSection.allCases[indexPath.section] {
        case .includingTags:
            if indexPath.row == includingTags.count {
                return tableView.dequeueReusableCell(withIdentifier: addTagIdentifier, for: indexPath)
            }
            return tagCell(for: tableView, cellForRowAt: indexPath, tags: includingTags)
        case .excludingTags:
            if indexPath.row == excludingTags.count {
                return tableView.dequeueReusableCell(withIdentifier: addTagIdentifier, for: indexPath)
            }
            return tagCell(for: tableView, cellForRowAt: indexPath, tags: excludingTags)
        }
    }

    private func tagCell(for tableView: UITableView,
                         cellForRowAt indexPath: IndexPath,
                         tags: [String]) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: reuseTagIdentifier, for: indexPath)
        guard indexPath.row < tags.count else { return cell }

        let tag: String = tags[indexPath.row]
        cell.textLabel?.text = tag
        return cell
    }

    // MARK: - Table view data delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        switch FilterTableSection.allCases[indexPath.section] {
        case .includingTags:
            guard
                let includingTagsSectionPosition = FilterTableSection.allCases.firstIndex(of: .includingTags),
                tableView.numberOfRows(inSection: includingTagsSectionPosition) == indexPath.row + 1 else { return }
            addNewTag(for: .includingTags)
        case .excludingTags:
            guard
                let excludingTagsSectionPosition = FilterTableSection.allCases.firstIndex(of: .excludingTags),
                tableView.numberOfRows(inSection: excludingTagsSectionPosition) == indexPath.row + 1 else { return }
            addNewTag(for: .excludingTags)
        }
    }

    func addNewTag(for section: FilterTableSection) {
        let alertController = UIAlertController(title: "Add New Tag", message: "", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Type the tag here"
        }
        let confirmAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard
                let tag = alertController.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                !tag.isEmpty,
                let includingTags = self?.includingTags,
                !includingTags.contains(tag),
                let excludingTags = self?.excludingTags,
                !excludingTags.contains(tag) else { return }
            switch section {
            case .includingTags: self?.includingTags.append(tag)
            case .excludingTags: self?.excludingTags.append(tag)
            }

            guard let sectionIndex = FilterTableSection.allCases.firstIndex(of: section) else { return }
            self?.tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
        }

        alertController.addAction(confirmAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch FilterTableSection.allCases[indexPath.section] {
        case .includingTags:
            return includingTags.count > indexPath.row
        case .excludingTags:
            return excludingTags.count > indexPath.row
        }
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        switch FilterTableSection.allCases[indexPath.section] {
        case .includingTags:
            includingTags.remove(at: indexPath.row)
        case .excludingTags:
            excludingTags.remove(at: indexPath.row)
        }

        tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
    }
}
