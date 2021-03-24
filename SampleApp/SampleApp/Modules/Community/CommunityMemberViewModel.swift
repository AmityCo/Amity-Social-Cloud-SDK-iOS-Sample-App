//
//  CommunityMemberViewModel.swift
//  SampleApp
//
//  Created by Nishan Niraula on 12/16/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation

struct CommunityMember: Identifiable {
    var id: String
    var title: String
    var roles: String = ""
    
    init(member: EkoCommunityMembership) {
        id = member.userId
        title = member.displayName
        if let memberRoles = member.roles as? [String], !memberRoles.isEmpty {
            roles = memberRoles.joined(separator: ",")
        }
    }
}

class CommunityMemberViewModel: ObservableObject {
    
    let communityId: String
    let commParticipation: EkoCommunityParticipation
    let commModeration: EkoCommunityModeration
    
    var token: EkoNotificationToken?
    var roleToFilter: String = ""
    
    @Published var roleUpdateStatus = ""
    @Published var permissionStatus = ""
    @Published var members: [CommunityMember] = []
    
    init(communityId: String) {
        self.communityId = communityId
        self.commParticipation = EkoCommunityParticipation(client: EkoManager.shared.client!, andCommunityId: communityId)
        self.commModeration = EkoCommunityModeration(client: EkoManager.shared.client!, andCommunity: communityId)
    }
    
    func addRole(role: String, userId: String) {
        self.commModeration.addRole(role, userIds: [userId]) { [weak self] (success, error) in
            self?.roleUpdateStatus = success ? "Role Added" : "Error"
        }
    }
    
    func removeRole(role: String, userId: String) {
        self.commModeration.removeRole(role, userIds: [userId]) { [weak self] (success, error) in
            self?.roleUpdateStatus = success ? "Role Removed" : "Error"
        }
    }
    
    func checkPermission(permission: EkoPermission) {
        EkoManager.shared.client?.hasPermission(permission, forCommunity: communityId, completion: { [weak self] hasPermission in
            self?.permissionStatus = hasPermission ? "Permission: True" : "Permission: False"
        })
    }
    
    func fetchFilteredMembers(roles: [String]) {
        self.members = []
        self.fetchMembers(roles: roles)
    }
    
    func fetchMembers(roles: [String]) {
        self.token = self.commParticipation.getMemberships(.all, roles: roles, sortBy: .lastCreated).observe({ [weak self] (collection,_, error) in
            
            var list = [CommunityMember]()
            for i in 0..<collection.count() {
                guard let member = collection.object(at: i) else { return }
                let model = CommunityMember(member: member)
                list.append(model)
            }
            
            self?.members = list
        })
    }
    
    func resetStatus() {
        roleUpdateStatus = ""
        permissionStatus = ""
    }
}

extension EkoPermission {
    
    var identifier: String {
        switch (self) {
        case .muteChannel:
            return "MUTE CHANNEL"
        case .closeChannel:
            return "CLOSE CHANNEL"
        case .editChannel:
            return "EDIT CHANNEL"
        case .editChannelRateLimit:
            return "EDIT CHANNEL RATELIMIT"
        case .editMessage:
            return "EDIT MESSAGE"
        case .deleteMessage:
            return "DELETE MESSAGE"
        case .banChannelUser:
            return "BAN CHANNEL USER"
        case .muteChannelUser:
            return "MUTE CHANNEL USER"
        case .addChannelUser:
            return "ADD CHANNEL USER"
        case .removeChannelUser:
            return "REMOVE CHANNEL USER"
        case .editChannelUser:
            return "EDIT CHANNEL USER"
        case .banUser:
            return "BAN USER"
        case .editUser:
            return "EDIT USER"
        case .assignUserRole:
            return "ASSIGN USER ROLE"
        case .editUserFeedPost:
            return "EDIT USER FEED POST"
        case .deleteUserFeedPost:
            return "DELETE USER FEED POST"
        case .editUserFeedComment:
            return "EDIT USER FEED COMMENT"
        case .deleteUserFeedComment:
            return "DELETE USER FEED COMMENT"
        case .addCommunityUser:
            return "ADD COMMUNITY USER"
        case .removeCommunityUser:
            return "REMOVE COMMUNITY USER"
        case .editCommunityUser:
            return "EDIT COMMUNITY USER"
        case .banCommunityUser:
            return "BAN COMMUNITY USER"
        case .muteCommunityUser:
            return "MUTE COMMUNITY USER"
        case .editCommunity:
            return "EDIT COMMUNITY"
        case .deleteCommunity:
            return "DELETE COMMUNITY"
        case .editCommunityPost:
            return "EDIT COMMUNITY POST"
        case .deleteCommunityPost:
            return "DELETE COMMUNITY POST"
        case .pinCommunityPost:
            return "PIN COMMUNITY POST"
        case .editCommunityComment:
            return "EDIT COMMUNITY COMMENT"
        case .deleteCommunityComment:
            return "DELETE COMMUNITY COMMENT"
        default:
            return ""
        }
        
    }
}
