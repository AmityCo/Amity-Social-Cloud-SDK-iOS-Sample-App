//
//  MessageDataSource.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/14/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import EkoChat

final class CommentsDataSource {
    private let commentsCollection: EkoCollection<EkoMessage>
    private var commentsToken: EkoNotificationToken?

    weak var dataSourceObserver: DataSourceListener?

    init(commentsCollection: EkoCollection<EkoMessage>) {
        self.commentsCollection = commentsCollection

        commentsToken = commentsCollection.observe { [weak self] _, _, _ in
            self?.dataSourceObserver?.didUpdateDataSource()
        }
    }

    func numberOfComments() -> Int {
        return Int(commentsCollection.count())
    }

    /// Since we want to display the newest message at the bottom of the table
    /// view, we need to flip the indexes order.
    func comment(for indexPath: IndexPath) -> EkoMessage? {
        let row: Int = Int(commentsCollection.count()) - (indexPath.row + 1)
        return commentsCollection.object(at: UInt(row))
    }

    func loadMore() {
        commentsCollection.nextPage()
    }
}
