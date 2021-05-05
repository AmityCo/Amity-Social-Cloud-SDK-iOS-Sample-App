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
        
        Log.add(info: "\n--- Community ---")
        Log.add(info: "Id: \(communityId) | Display Name: \(displayName)")
        Log.add(info: "Avatar: id: \(String(describing: community.avatar?.fileId)) | Attributes: \(String(describing: community.avatar?.attributes))")
        Log.add(info: "Category Id: \(String(describing: categoryIds))")
        Log.add(info: "Categories: \(community.categories.map{ $0.categoryId })")
        Log.add(info: "User Id: \(userId) | Display Name: \(String(describing: community.user?.displayName))")
    }
    
    func getCommunityObject() -> AmityCommunity {
        return communityObject
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
    
    var searchKeyword: String = "" {
        didSet {
            queryCommunity()
        }
    }
    
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
            for index in (0..<collection.count()) {
                guard let object = collection.object(at: index) else { continue }
                let model = CommunityListModel(community: object)
                list.append(model)
            }
            self.community = list
        })
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
        
        Log.add(info: "[Community] Categories collection updated")
        
        var models = [CommunityCategoryModel]()
        
        for index in 0..<collection.count() {
            guard let category = collection.object(at: index) else { continue }
            
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
    
    func leaveCommunity(for community: CommunityListModel, completion: ((Bool, Error?) -> Void)?) {
        communityRepository.leaveCommunity(withId: community.communityId) { [weak self] (success, error) in
            guard let self = self else { return }
            if let index = self.community.firstIndex(where: { $0.communityId == community.communityId }) {
                self.community[index].isJoined = false
                self.community[index].membersCount -= 1
            }
            completion?(success, error)
        }
    }
}

