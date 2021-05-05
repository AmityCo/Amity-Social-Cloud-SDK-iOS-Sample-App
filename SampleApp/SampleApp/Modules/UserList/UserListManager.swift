//
//  UserListManager.swift
//  SampleApp
//
//  Created by Nishan Niraula on 5/11/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation

class UserListManager {
    
    let client: AmityClient
    let userRepository: AmityUserRepository
    
    var userCollection: AmityCollection<AmityUser>?
    var userCollectionToken: AmityNotificationToken?
    
    var searchCollection: AmityCollection<AmityUser>?
    var searchCollectionToken: AmityNotificationToken?
    
    var isInSearchMode = false
    var searchText = ""
    var sortOption: AmityUserSortOption = .displayName
    
    let debouncer = Debouncer(delay: 0.3)
    var searchedUsers = [AmityUser]()
    
    init(client: AmityClient) {
        self.client = client
        self.userRepository = AmityUserRepository(client: client)
    }
    
    func fetchUserList(sortedBy option: AmityUserSortOption, completion:@escaping ()->()) {
        userCollection = userRepository.getUsers(option)
        userCollectionToken = userCollection?.observe({ (collection, change, error) in
            guard !self.isInSearchMode else { return }

            completion()
        })
    }
    
    func searchUserList(name: String, completion:@escaping ()->()) {
        self.searchText = name
        self.isInSearchMode = !name.isEmpty
        
        if isInSearchMode {
            self.searchedUsers = []
            completion()
            
            debouncer.setCallback { [weak self] in
                self?.waitAndSearchUser(name: name, completion: completion)
            }
            debouncer.call()
        } else {
            completion()
        }
    }
    
    func waitAndSearchUser(name: String, completion:@escaping ()->()) {
        
        searchCollection = userRepository.searchUser(name, sortBy: self.sortOption)
        searchCollectionToken = searchCollection?.observe({ [weak self] (collection, change, error) in
            
            self?.populateSearchedUsers(completion: completion)
        })
    }
    
    func populateSearchedUsers(completion:@escaping ()->()) {
        
        var results = [AmityUser]()
        for i in 0..<searchCollection!.count() {
            guard let item = searchCollection!.object(at: UInt(i)) else { continue }
            results.append(item)
        }
        
        self.searchedUsers = results
        
        // Notify tableview to reload
        completion()
    }
    
    func numberOfUsers() -> Int {
        if isInSearchMode {
            return searchedUsers.count
        } else {
            return Int(userCollection?.count() ?? 0)
        }
    }
    
    func getUserItem(at index: Int) -> AmityUser? {
        if isInSearchMode {
            return searchedUsers[index]
        } else {
            return userCollection?.object(at: UInt(index))
        }
    }
    
    func loadMoreUsers() {
        if isInSearchMode {
            guard let hasMorePosts = searchCollection?.hasNext, hasMorePosts else { return }
            searchCollection?.nextPage()
        } else {
            guard let hasMorePosts = userCollection?.hasNext, hasMorePosts else { return }
            userCollection?.nextPage()
        }
    }
}


// Simple debouncer for search
@objc public class Debouncer: NSObject {
    
    @objc public var delay: Double
    
    private var callback: (() -> Void)?
    
    private weak var timer: Timer?
    
    @objc public init(delay: TimeInterval) {
        self.delay = delay
    }
    
    deinit {
        timer?.invalidate()
    }
    
    @objc public func setCallback(_ callback: (() -> Void)?) {
        self.callback = callback
    }
    
    @objc public func call() {
        timer?.invalidate()
        let nextTimer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(fire), userInfo: nil, repeats: false)
        timer = nextTimer
    }
    
    @objc public func fire() {
        self.callback?()
    }
    
}
