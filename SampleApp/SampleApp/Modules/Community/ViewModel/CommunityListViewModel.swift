//
//  CommunityListViewModel.swift
//  SampleApp
//
//  Created by Michael Abadi on 13/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation
import AmitySDK

struct CommunityListModel: Identifiable, Equatable {

    let communityObject: AmityCommunity
    
    static func == (lhs: CommunityListModel, rhs: CommunityListModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String {
        return communityId
    }
    let communityId: String
    let description: String
    let displayName: String
    let isPublic: Bool
    let isOfficial: Bool
    var isJoined: Bool = false
    let channelId: String
    let postsCount: Int
    var membersCount: Int
    let createdAt: Date
    let metadata: [String: Any]?
    let userId: String
    let tags: [String]
    let categoryIds: [String]?
    let isPostReview: Bool
    
    var isCreator: Bool {
        return AmityManager.shared.client?.currentUserId == userId
    }
    
    init(community: AmityCommunity) {
        communityObject = community
        communityId = community.communityId
        description = community.communityDescription
        displayName = community.displayName
        isPublic = community.isPublic
        isOfficial = community.isOfficial
        isJoined = community.isJoined
        channelId = community.channelId
        postsCount = Int(community.postsCount)
        membersCount = Int(community.membersCount)
        createdAt = community.createdAt
        metadata = community.metadata
        userId = community.userId
        tags = community.tags ?? []
        categoryIds = community.categoryIds
        isPostReview = community.isPostReviewEnabled
    }
    
    func getCommunityObject() -> AmityCommunity {
        return communityObject
    }
    
    func getPreviewData() -> [(key: String, value: String)] {
        var items = [(key: String, value: String)]()
        
        items.append(("Community Id:", "\(communityId)"))
        items.append(("Channel Id:", "\(channelId)"))
        items.append(("Is Public:", "\(isPublic ? "YES" : "NO")"))
        items.append(("Is Post Review Enabled", "\(isPostReview ? "YES" : "NO")"))
        items.append(("MetaData:", "\(metadata?.description ?? "")"))
        items.append(("Post Count:", "\(postsCount)"))
        items.append(("Post Published Count:", "\(getCommunityObject().getPostCount(feedType: .published))"))
        items.append(("Post Reviewing Count:", "\(getCommunityObject().getPostCount(feedType: .reviewing))"))
        items.append(("Members Count:", "\(membersCount)"))
        items.append(("Created At:", "\(createdAt)"))
        items.append(("Categories Count:", "\(categoryIds?.count ?? 0)"))
        items.append(("Categories","\(communityObject.categories.map{ $0.name }.joined(separator: ","))"))
        
        return items
    }
}

struct CommunityCategoryModel: Identifiable {
    
    let name: String
    let id: String
    let fileId: String
    
    init(id: String, name: String, fileId: String) {
        self.id = id
        self.name = name
        self.fileId = fileId
    }
}

enum CommunityType: String {
    case normal = "Default"
    case trending = "Trending"
    case recommended = "Recommended"
}

// Concrete implementor
class CommunityListViewModel: ObservableObject {
    
    var type: CommunityType
    var pageTitle: String
    
    private let communityRepository = AmityCommunityRepository(client: AmityManager.shared.client!)
    
    private var token: AmityNotificationToken?
    private var communityCollection: AmityCollection<AmityCommunity>?
    
    var debouncer = Debouncer(delay: 0.3)
    
    var searchKeyword: String = ""
    
    private var filter: AmityCommunityQueryFilter = .all
    private var sort: AmityCommunitySortOption = .lastCreated
    
    private var categoryCollectionToken:AmityNotificationToken?
    private var categoryColllection: AmityCollection<AmityCommunityCategory>?
    
    @Published var categories = [CommunityCategoryModel]()
    @Published var community: [CommunityListModel] = []
    
    var currentSortOption: AmityCommunityCategoriesSortOption = .displayName
    var shouldIncludeDeletedCategories = false
    
    init(type: CommunityType) {
        self.type = type
        self.pageTitle = type.rawValue
    }
    
    func queryCommunity() {
        community.removeAll()
        
        switch type {
        case .normal:
            communityCollection = communityRepository.getCommunities(displayName: searchKeyword, filter: filter, sortBy: sort, categoryId: nil, includeDeleted: shouldIncludeDeletedCategories)
        case .recommended:
            communityCollection = communityRepository.getRecommendedCommunities()
        case .trending:
            communityCollection = communityRepository.getTrendingCommunities()
        }
        
        token?.invalidate()
        token = communityCollection?.observe({ [weak self] (collection, _, _) in
            guard let self = self else { return }
            var list = [CommunityListModel]()
            for community in collection.allObjects() {
                let model = CommunityListModel(community: community)
                list.append(model)
            }
            self.community = list
        })
    }
    
    func searchCommunities() {
        self.queryCommunity()
    }
    
    func queryAllCategories() {
        sortCategories(sortOption: .displayName)
    }
    
    func sortCategories(sortOption: AmityCommunityCategoriesSortOption) {
        self.currentSortOption = sortOption
        
        switch sortOption {
        case .displayName:
            categoryColllection = communityRepository.getCategories(sortBy: .displayName, includeDeleted: shouldIncludeDeletedCategories)
        case .firstCreated:
            categoryColllection = communityRepository.getCategories(sortBy: .firstCreated, includeDeleted: shouldIncludeDeletedCategories)
        case .lastCreated:
            categoryColllection = communityRepository.getCategories(sortBy: .lastCreated, includeDeleted: shouldIncludeDeletedCategories)
        @unknown default:
            fatalError()
        }
        
        categoryCollectionToken = categoryColllection?.observe({ (collection, _, _) in
            self.updateCategoryList()
        })
    }
    
    func reloadCategories() {
        sortCategories(sortOption: self.currentSortOption)
    }
    
    func updateCategoryList() {
        guard let collection = categoryColllection else { return }
        
        var models = [CommunityCategoryModel]()
        
        for category in collection.allObjects() {
            Log.add(info: "Category Name: \(category.name)")
            Log.add(info: "Category AvatarId: \(category.avatarFileId)")
            Log.add(info: "Category Avatar: \(category.avatar?.fileId ?? "")")
            
            let model = CommunityCategoryModel(id: category.categoryId, name: category.name, fileId: category.avatarFileId)
            models.append(model)
        }
        
        self.categories = models
    }
    
    func setSort(_ sort: AmityCommunitySortOption) {
        self.sort = sort
        queryCommunity()
    }
    
    func setFilter(_ filter: AmityCommunityQueryFilter) {
        self.filter = filter
        queryCommunity()
    }
    
    func fetchNextPage() {
        guard communityCollection?.hasNext ?? false else { return }
        communityCollection?.nextPage()
    }
    
    func deleteCommunity(for community: CommunityListModel, completion: ((Bool, Error?) -> Void)?) {
        communityRepository.deleteCommunity(withId: community.communityId) { [weak self] (success, error) in
            guard let self = self else { return }
            if let index = self.community.firstIndex(where: { $0.communityId == community.communityId }) {
                self.community.remove(at: index)
            }
            completion?(success, error)
        }
    }
    
    func joinCommunity(for community: CommunityListModel, completion: ((Bool, Error?) -> Void)?) {
        communityRepository.joinCommunity(withId: community.communityId) { [weak self] (success, error) in
            guard let self = self else { return }
            if let index = self.community.firstIndex(where: { $0.communityId == community.communityId }) {
                self.community[index].isJoined = true
                self.community[index].membersCount += 1
            }
            completion?(success, error)
        }
    }
    
    func leaveCommunity(for community: CommunityListModel, completion: ((Bool, NSError?) -> Void)?) {
        communityRepository.leaveCommunity(withId: community.communityId) { [weak self] (success, error) in
            guard let self = self else { return }
            if let error = error {
                completion?(false, error as NSError)
                Log.add(info: error)
                return
            }
            
            if let index = self.community.firstIndex(where: { $0.communityId == community.communityId }) {
                self.community[index].isJoined = false
                self.community[index].membersCount -= 1
            }
            
            completion?(success, nil)
        }
    }
}
