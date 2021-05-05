//
//  ReactionDatasource.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 12/30/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import AmitySDK

final class ReactionDatasource {
    private let reactionsCollection: AmityCollection<AmityReaction>
    private var reactionsToken: AmityNotificationToken?
    private let reverse: Bool
    weak var dataSourceObserver: DataSourceListener?

    init(reactionsCollection: AmityCollection<AmityReaction>, reverse: Bool) {
        self.reactionsCollection = reactionsCollection
        self.reverse = reverse

        reactionsToken = reactionsCollection.observe { [weak self] _, _, _ in
            self?.dataSourceObserver?.didUpdateDataSource()
        }
    }
    
    func numberOfReactions() -> Int {
        return Int(reactionsCollection.count())
    }

    func reaction(for indexPath: IndexPath) -> AmityReaction? {
        let row: Int
        if reverse {
            row = numberOfReactions() - (indexPath.row + 1)
        } else {
            row = indexPath.row
        }

        return reactionsCollection.object(at: UInt(row))
    }

    func loadMore() {
        if reverse {
            reactionsCollection.previousPage()
        } else {
            reactionsCollection.nextPage()
        }
    }
}
