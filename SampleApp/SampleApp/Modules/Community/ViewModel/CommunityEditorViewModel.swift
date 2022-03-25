//
//  CommunityEditorViewModel.swift
//  SampleApp
//
//  Created by Michael Abadi on 13/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit
import AmitySDK

struct CommunityDraft: Codable {
    
    internal init(identifier: String?, isPrivate: Bool, displayName: String, description: String, userIds: [String], tags: [String], key: String, value: String, membersCount: Int = 0, categoryId: String, isPostReview: Bool) {
        self.identifier = identifier
        self.isPrivate = isPrivate
        self.displayName = displayName
        self.description = description
        self.userIds = userIds
        self.tags = tags
        self.key = key
        self.value = value
        self.membersCount = membersCount
        self.categoryId = categoryId
        self.isPostReview = isPostReview
    }
    
    let identifier: String?
    var isPrivate: Bool
    var displayName: String
    var description: String
    var userIds: [String]
    var tags: [String]
    var key: String
    var value: String
    var membersCount: Int = 0
    var categoryId: String
    var isPostReview: Bool
    
    var metadata: [String: String]? {
        if key == "" || value == "" {
            return nil
        }
        return [
            key: value
        ]
    }
    
    init(community: CommunityListModel) {
        self = CommunityDraft(identifier: community.id, isPrivate: !community.isPublic, displayName: community.displayName, description: community.description, userIds: [community.userId], tags: community.tags, key: community.metadata?.keys.first ?? "", value: community.metadata?.description ?? "", membersCount: community.membersCount, categoryId: community.categoryIds?.first ?? "", isPostReview: community.isPostReview)
    }
}

protocol CommunityEditorDatasource {
    var draft: CommunityDraft { get set }
    var isEditorLoading: Bool { get }
    var isEditMode: Bool { get }
}

protocol CommunityEditorAction {
    func createCommunity(completion: @escaping (_ success: Bool, _ error: Error?) -> Void)
    func updateCommunity(completion: @escaping (_ success: Bool, _ error: Error?) -> Void)
    func deleteCommunity(completion: @escaping (_ success: Bool, _ error: Error?) -> Void)
}

// Base model protocol
protocol EditorViewModel: ObservableObject {
    var action: CommunityEditorAction { get }
    var datasource: CommunityEditorDatasource { get set }
}

// Concrete implementor
class CommunityEditorViewModel: EditorViewModel, CommunityEditorDatasource, CommunityEditorAction {
        
    private let communityRepository = AmityCommunityRepository(client: AmityManager.shared.client!)
    private let fileRepository = AmityFileRepository(client: AmityManager.shared.client!)
    
    @Published var draft: CommunityDraft = CommunityDraft(identifier: nil, isPrivate: false, displayName: "", description: "", userIds: [], tags: [], key: "", value: "", categoryId: "", isPostReview: false)
    @Published var isEditorLoading: Bool = false
    @Published var isEditMode: Bool = false
    
    init(draft: CommunityDraft = CommunityDraft(identifier: nil, isPrivate: false, displayName: "", description: "", userIds: [], tags: [], key: "", value: "", categoryId: "", isPostReview: false)) {
        self.draft = draft
        if draft.identifier != nil {
            isEditMode = true
        }
    }
    
    func uploadAvatar(image: UIImage, completion:@escaping (AmityImageData?) -> Void) {
        fileRepository.uploadImage(image, progress: nil) { (imageData, error) in
            completion(imageData)
        }
    }
    
    func createCommunity(completion: @escaping (Bool, Error?) -> Void) {
        
        uploadAvatar(image: UIImage(named: "pikachu")!) { [weak self] data in
            self?.createCommunityWithBuilder(imageData: data, completion: completion)
        }
    }
    
    func createCommunityWithBuilder(imageData: AmityImageData?, completion: @escaping (Bool, Error?) -> Void) {
        let builder = AmityCommunityCreationDataBuilder()
        builder.setDisplayName(draft.displayName)
        var finalUserId = draft.userIds.compactMap({$0})
        if !finalUserId.contains(AmityManager.shared.client!.currentUserId!) {
            finalUserId.append(AmityManager.shared.client!.currentUserId!)
        }
        builder.setUserIds(finalUserId)
        builder.setCommunityDescription(draft.description)
        builder.setIsPublic(!draft.isPrivate)
        builder.isPostReviewEnabled(draft.isPostReview)
        if let data = imageData {
            builder.setAvatar(data)
        }
        
        if !draft.categoryId.isEmpty {
            builder.setCategoryIds([draft.categoryId])
        }
        
        if draft.metadata != nil {
            builder.setMetadata(draft.metadata!)
        }
        isEditorLoading = true
        
        communityRepository.createCommunity(with: builder, completion: { (community, error) in
            
            self.isEditorLoading = false
            completion(true, error)
        })
    }
    
    func updateCommunity(completion: @escaping (Bool, Error?) -> Void) {
        updateCommunityWithBuilder(imageData: nil, completion: completion)
    }
    
    func updateCommunityWithBuilder(imageData: AmityImageData?, completion: @escaping (Bool, Error?) -> Void) {
        
        let builder = AmityCommunityUpdateDataBuilder()
        builder.setDisplayName(draft.displayName)
        builder.setCommunityDescription(draft.description)
        builder.setIsPublic(!draft.isPrivate)
        builder.setAvatar(imageData)
        builder.isPostReviewEnabled(draft.isPostReview)
        if !draft.categoryId.isEmpty {
            builder.setCategoryIds([draft.categoryId])
        }
        
        if draft.metadata != nil {
            builder.setMetadata(draft.metadata!)
        }
        
        communityRepository.updateCommunity(withId: draft.identifier!, builder: builder, completion: { [weak self] (community, error) in
            self?.isEditorLoading = false
            
            if let err = error {
                Log.add(info: "Error while updating community")
                completion(false, err)
            } else {
                Log.add(info: "Community updated successfully")
                
                Log.add(info: "Community Display Name: \(String(describing: community?.displayName))")
                Log.add(info: "Community Avatar: \(String(describing: community?.avatar?.attributes))")
                
                completion(true, nil)
            }
        })
    }
    
    func deleteCommunity(completion: @escaping (Bool, Error?) -> Void) {
        communityRepository.deleteCommunity(withId: draft.identifier!) { [weak self] (success, error) in
            self?.isEditorLoading = false
            completion(success, error)
        }
    }
    
    private lazy var _datasource: CommunityEditorDatasource = {
        return self
    }()
    
    var datasource: CommunityEditorDatasource {
        get {
            return _datasource
        }
        set {
            _datasource = newValue
        }
    }
    
    var action: CommunityEditorAction { return self}

}
