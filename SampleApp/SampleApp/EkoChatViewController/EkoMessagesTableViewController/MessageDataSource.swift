//
//  MessageDataSource.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/14/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import EkoChat

final class MessageDataSource {
    private let messagesCollection: EkoCollection<EkoMessage>
    private var messagesToken: EkoNotificationToken?
    private let reverse: Bool
    weak var dataSourceObserver: DataSourceListener?

    init(messagesCollection: EkoCollection<EkoMessage>, reverse: Bool) {
        self.messagesCollection = messagesCollection
        self.reverse = reverse

        messagesToken = messagesCollection.observe { [weak self] _, _, _ in
            Log.add(info: "Message Changed ")
            self?.dataSourceObserver?.didUpdateDataSource()
        }
    }

    func numberOfMessages() -> Int {
        return Int(messagesCollection.count())
    }

    func message(for indexPath: IndexPath) -> EkoMessage? {
        let row: Int
        if reverse {
            row = numberOfMessages() - (indexPath.row + 1)
        } else {
            row = indexPath.row
        }

        return messagesCollection.object(at: UInt(row))
    }

    func loadMore() {
        if reverse {
            messagesCollection.previousPage()
        } else {
            messagesCollection.nextPage()
        }
    }
}
