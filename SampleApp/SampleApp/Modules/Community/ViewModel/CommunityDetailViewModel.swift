//
//  CommunityDetailViewModel.swift
//  SampleApp
//
//  Created by Michael Abadi on 23/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation
import AmitySDK

class CommunityNotification {
    let events: [CommunityNotificationEvent]
    let isPushEnabled: Bool
    let isUserEnabled: Bool
    
    init(notification: AmityCommunityNotificationSettings) {
        self.isPushEnabled = notification.isEnabled
        self.isUserEnabled = notification.isUserEnabled
        self.events = notification.events.map(CommunityNotificationEvent.init)
    }
    
}

class CommunityNotificationEvent: Identifiable {
    
    var id: String {
        return name
    }
    
    let name: String
    let isNetworkEnabled: Bool
    let isPushEnabled: Bool
    let roles: [String]
    let eventType: AmityCommunityNotificationEventType
    
    init(notificationEvent: AmityCommunityNotificationEvent) {
        self.name = notificationEvent.eventName
        self.isNetworkEnabled = notificationEvent.isNetworkEnabled
        self.isPushEnabled = notificationEvent.isEnabled
        self.roles = notificationEvent.roleFilter?.roleIds ?? []
        self.eventType = notificationEvent.eventType
    }
    
    var tittle: String {
        switch eventType {
        case .postCreated: return "New Posts"
        case .postReacted: return "Reacts Posts"
        case .commentReacted: return "Reacts Comments"
        case .commentCreated: return "Comments"
        case .commentReplied: return "Replies"
        @unknown default:
            fatalError()
        }
    }
}

struct CommunityPostModel: Identifiable, Equatable {
    static func == (lhs: CommunityPostModel, rhs: CommunityPostModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String {
        return postId
    }
    
    let postId: String
    let postedUserDisplayName: String?
    let text: String?
    let feedType: AmityFeedType
    let isDeleted: Bool
    let postDataType: String
    let isOwner: Bool
    let createdAt: Date
    let metadata: [String: Any]?
    let mentionees: [AmityMentionees]?
}

// Concrete implementor
class CommunityDetailViewModel: ObservableObject {

    private let feedRepository = AmityFeedRepository(client: AmityManager.shared.client!)
    private let communityRepository = AmityCommunityRepository(client: AmityManager.shared.client!)
    
    private var token: AmityNotificationToken?
    private var postCollection: AmityCollection<AmityPost>?
    
    private var filter: AmityCommunityQueryFilter = .all
    private var sort: AmityPostQuerySortOption = .firstCreated
    var community: CommunityListModel
    
    @Published var feed = [CommunityPostModel]()
    @Published var updateFeed: Bool
    @Published var communityNotification: CommunityNotification?
    @Published var showNotificationErrorAlert: Bool
        
    var feedType: AmityFeedType = .published
    
    init(community: CommunityListModel) {
        self.community = community
        self.feed = []
        self.updateFeed = true
        self.showNotificationErrorAlert = false
        self.queryNotificationSetting()
    }
    
    func queryFeed(sort: AmityPostQuerySortOption) {
        feed = []
        postCollection = feedRepository.getCommunityFeed(withCommunityId: community.id, sortBy: sort, includeDeleted: false, feedType: feedType)
        token = postCollection?.observe({ [weak self] (collection, _, _) in
            guard collection.dataStatus == .fresh, let strongSelf = self else { return }
            
            self?.token?.invalidate()
            Log.add(info: "Feed observed: \(collection.dataStatus.description), post count: \(collection.count())")
            
            var list = [CommunityPostModel]()
            for post in collection.allObjects() {
                let model = CommunityPostModel(postId: post.postId,
                                               postedUserDisplayName: post.postedUser?.displayName,
                                               text: post.data?["text"] as? String,
                                               feedType: post.getFeedType(),
                                               isDeleted: post.isDeleted,
                                               postDataType: post.dataType,
                                               isOwner: post.postedUserId == AmityManager.shared.client?.currentUserId,
                                               createdAt: post.createdAt,
                                               metadata: post.metadata,
                                               mentionees: post.mentionees)
                list.append(model)
            }
            
            strongSelf.feed = list
            strongSelf.updateFeed.toggle()
        })
    }
    
    func queryNotificationSetting() {
        let communityManager = communityRepository.notificationManager(forCommunityId: community.id)
        
        communityManager.getSettingsWithCompletion { [weak self] (model, error) in
            guard let notification = model else { return }
            self?.communityNotification = CommunityNotification(notification: notification)
        }
    }
    
    func updateNoticommunityRepositoryzfication(isPushEnabled: Bool, events: [AmityCommunityNotificationEvent]) {
        let communityManager = communityRepository.notificationManager(forCommunityId: community.id)
        if isPushEnabled {
            communityManager.enable(for: events) { [weak self] (success, error) in
                if let error = error as NSError? {
                    if error.code == 400319 {
                        self?.showNotificationErrorAlert = true
                    }
                } else if success {
                    self?.queryNotificationSetting()
                }
            }
        } else {
            communityManager.disable { [weak self] (success, error) in
                if success {
                    self?.queryNotificationSetting()
                }
            }
        }
    }
    
    func fetchNextPage() {
        postCollection?.nextPage()
    }

}
