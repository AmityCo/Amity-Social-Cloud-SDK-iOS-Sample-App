//
//  ChannelTagsTableViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 4/19/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import EkoChat

private let reuseIdentifier: String = "tagCellIdentifier"
private let addTagIdentifier: String = "addTagIdentifier"

final class ChannelTagsTableViewController: UITableViewController, DataSourceListener {
    weak var client: EkoClient!
    var channelId: String!

    private var dataSource: ChannelTagsDataSource!
    private lazy var channelRepo: EkoChannelRepository = EkoChannelRepository(client: client)

    private enum Section: CaseIterable {
        case tagList, addTag
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        let sampleAppCellNib = UINib(nibName: "SampleAppTableViewCell", bundle: nil)
        tableView.register(sampleAppCellNib, forCellReuseIdentifier: reuseIdentifier)

        let addTagCellNnib = UINib(nibName: "AddTagTableViewCell", bundle: nil)
        tableView.register(addTagCellNnib, forCellReuseIdentifier: addTagIdentifier)

        dataSource = ChannelTagsDataSource(client: client, channelId: channelId)
        dataSource.dataSourceObserver = self

        // removes empty cells in UITableView
        tableView.tableFooterView = UIView()

        title = "Channel Tags"
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section: Section = Section.allCases[section]
        switch section {
        case .tagList: return dataSource.numberOfTags()
        case .addTag: return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section: Section = Section.allCases[indexPath.section]
        switch section {
        case .tagList: return dequeueTagCell(tableView, cellForRowAt: indexPath)
        case .addTag: return dequeueAddTagCell(tableView, cellForRowAt: indexPath)
        }

    }

    private func dequeueTagCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tag: String = dataSource.tag(for: indexPath) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        guard let tagTableViewCell = cell as? SampleAppTableViewCell else { return UITableViewCell() }

        tagTableViewCell.titleLabel.text = tag

        return tagTableViewCell
    }

    private func dequeueAddTagCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: addTagIdentifier)!
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section: Section = Section.allCases[section]
        switch section {
        case .tagList: return "Tags"
        case .addTag: return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let section: Section = Section.allCases[section]
        switch section {
        case .tagList: return "Swipe left to remove a tag."
        case .addTag: return nil
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }

        let section: Section = Section.allCases[indexPath.section]
        guard section == .addTag else { return }
        addNewTag()
    }

    func addNewTag() {
        let alertController = UIAlertController(title: "Add New Tag", message: "", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Type the tag here"
        }
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard
                let dataSource = self?.dataSource,
                let channelId = self?.channelId,
                let tag = alertController.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                !tag.isEmpty else { return }

            var tags: [String] = []
            for index in 0..<dataSource.numberOfTags() {
                guard let tag = dataSource.tag(for: IndexPath(row: index, section: 0)) else { return }
                tags.append(tag)
            }
            tags.append(tag)

            self?.channelRepo.setTagsForChannel(channelId, tags: tags)
        }

        alertController.addAction(addAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section: Section = Section.allCases[indexPath.section]
        return section == .tagList
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        var tags: [String] = []
        for index in 0..<dataSource.numberOfTags() where index != indexPath.row {
            guard let tag = dataSource.tag(for: IndexPath(row: index, section: 0)) else { return }
            tags.append(tag)
        }

        channelRepo.setTagsForChannel(channelId, tags: tags)
    }

    // MARK: DataSourceListener

    func didUpdateDataSource() {
        tableView.reloadData()
    }
}
