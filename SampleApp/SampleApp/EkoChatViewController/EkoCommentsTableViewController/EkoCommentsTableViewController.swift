//
//  EkoMessagesTableViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/13/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import EkoChat

private let kContentOffsetY: CGFloat = 10
private let kContentOffsetX: CGFloat = 0

final class EkoCommentsTableViewController: UITableViewController, DataSourceListener {
    typealias EkoComment = EkoMessage
    // to be injected.
    @objc var client: EkoClient!
    @objc var channelId: String!
    weak var delegate: CommentsDelegate?
    private var dataSource: CommentsDataSource?

    var parentId: String?

    private func observeComments() {
        let commentsRepository = EkoMessageRepository(client: client)
        let commentsCollection: EkoCollection<EkoComment>
        commentsCollection = commentsRepository.messages(withChannelId: channelId,
                                                         filterByParentId: true,
                                                         parentId: parentId,
                                                         reverse: true)

        dataSource = CommentsDataSource(commentsCollection: commentsCollection)
        dataSource?.dataSourceObserver = self
    }

    @objc func scrollToBottom() {
        guard
            let commentsCount = dataSource?.numberOfComments(),
            commentsCount > 0 else { return }
        tableView.layoutIfNeeded()
        let indexPath: IndexPath = IndexPath(item: commentsCount - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        parentId = UserDefaults.standard.parentId
        UserDefaults.standard.parentId = nil

        tableView.contentInset = UIEdgeInsets(top: kContentOffsetY, left: kContentOffsetX,
                                              bottom: kContentOffsetY, right: kContentOffsetX)
        observeComments()
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.numberOfComments() ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if
            let comment: EkoComment = comment(for: indexPath),
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell",
                                                     for: indexPath) as? CommentTableViewCell {
            cell.display(comment, client: client)
            return cell
        }
        return UITableViewCell()
    }

    private func comment(for indexPath: IndexPath) -> EkoMessage? {
        return dataSource?.comment(for: indexPath)
    }

    private func height(for size: CGSize, withinSize newSize: CGSize) -> CGFloat {
        let aspectWidth: CGFloat = newSize.width / size.width
        let aspectHeight: CGFloat = newSize.height / size.height
        let aspectRatio: CGFloat = min(aspectWidth, aspectHeight)

        return size.height * aspectRatio
    }

    // MARK: UITableViewDelegate

    override func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                            withVelocity velocity: CGPoint,
                                            targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // load previous page when scrolled to the top
        if targetContentOffset.pointee.y.isLessThanOrEqualTo(0) {
            dataSource?.loadMore()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard let comment = comment(for: indexPath) else { return }

        delegate?.seeComments(for: comment.messageId)
    }

    // MARK: DataSourceListener

    func didUpdateDataSource() {
        tableView.reloadData()

        // scroll to last row on refresh
        scrollToBottom()
    }
}
