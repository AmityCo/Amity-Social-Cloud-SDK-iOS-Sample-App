//
//  CommunityEditorViewModel.swift
//  SampleApp
//
//  Created by Michael Abadi on 13/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation
import EkoChat

struct CommunityDraft: Codable {
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
    
    var metadata: [String: String]? {
        if key == "" || value == "" {
            return nil
        }
        return [
            key: value
        ]
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
        
    private let communityRepository = EkoCommunityRepository(client: EkoManager.shared.client!)
    private let fileRepository = EkoFileRepository(client: EkoManager.shared.client!)
    
    @Published var draft: CommunityDraft = CommunityDraft(identifier: nil, isPrivate: false, displayName: "", description: "", userIds: [], tags: [], key: "", value: "", categoryId: "")
    @Published var isEditorLoading: Bool = false
    @Published var isEditMode: Bool = false
    
    init(draft: CommunityDraft = CommunityDraft(identifier: nil, isPrivate: false, displayName: "", description: "", userIds: [], tags: [], key: "", value: "", categoryId: "")) {
        self.draft = draft
        if draft.identifier != nil {
            isEditMode = true
        }
    }
    
    func uploadAvatar(image: UIImage, completion:@escaping (EkoImageData?) -> Void) {
        fileRepository.uploadImage(image, progress: nil) { (imageData, error) in
            completion(imageData)
        }
    }
    
    func createCommunity(completion: @escaping (Bool, Error?) -> Void) {
        
        uploadAvatar(image: UIImage(named: "pikachu")!) { [weak self] data in
            self?.createCommunityWithBuilder(imageData: data, completion: completion)
        }
    }
    
    func createCommunityWithBuilder(imageData: EkoImageData?, completion: @escaping (Bool, Error?) -> Void) {
        let builder = EkoCommunityCreationDataBuilder()
        builder.setDisplayName(draft.displayName)
        var finalUserId = draft.userIds.compactMap({$0})
        if !finalUserId.contains(EkoManager.shared.client!.currentUserId!) {
            finalUserId.append(EkoManager.shared.client!.currentUserId!)
        }
        builder.setUserIds(finalUserId)
        builder.setCommunityDescription(draft.description)
        builder.setIsPublic(!draft.isPrivate)
        
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
        
        communityRepository.createCommunity(builder, completion: { (community, error) in
            
            self.isEditorLoading = false
            completion(true, error)
        })
    }
    
    func updateCommunity(completion: @escaping (Bool, Error?) -> Void) {
        updateCommunityWithBuilder(imageData: nil, completion: completion)
    }
    
    func updateCommunityWithBuilder(imageData: EkoImageData?, completion: @escaping (Bool, Error?) -> Void) {
        
        let builder = EkoCommunityUpdateDataBuilder()
        builder.setDisplayName(draft.displayName)
        builder.setCommunityDescription(draft.description)
        builder.setIsPublic(!draft.isPrivate)
        builder.setAvatar(imageData)
        
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