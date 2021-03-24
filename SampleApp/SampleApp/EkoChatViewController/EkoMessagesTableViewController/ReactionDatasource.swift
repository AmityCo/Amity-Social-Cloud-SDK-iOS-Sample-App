//
//  ReactionDatasource.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 12/30/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import EkoChat

final class ReactionDatasource {
    private let reactionsCollection: EkoCollection<EkoReaction>
    private var reactionsToken: EkoNotificationToken?
    private let reverse: Bool
    weak var dataSourceObserver: DataSourceListener?

    init(reactionsCollection: EkoCollection<EkoReaction>, reverse: Bool) {
        self.reactionsCollection = reactionsCollection
        self.reverse = reverse

        reactionsToken = reactionsCollection.observe { [weak self] _, _, _ in
            self?.dataSourceObserver?.didUpdateDataSource()
        }
    }
    
    func numberOfReactions() -> Int {
        return Int(reactionsCollection.count())
    }

    func reaction(for indexPath: IndexPath) -> EkoReaction? {
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
