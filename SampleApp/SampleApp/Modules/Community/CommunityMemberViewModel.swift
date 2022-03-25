//
//  CommunityMemberViewModel.swift
//  SampleApp
//
//  Created by Nishan Niraula on 12/16/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation

struct CommunityMember: Identifiable {
    let id: String
    let displayName: String
    var roles: String = ""
    let isBanned: Bool
    
    init(member: AmityCommunityMember) {
        id = member.userId
        displayName = member.displayName
        isBanned = member.isBanned
        if !member.roles.isEmpty {
            roles = member.roles.joined(separator: ",")
        }
    }
    
    init(member: AmityUser) {
        id = member.userId
        displayName = member.displayName ?? member.userId
        isBanned = false
        if !member.roles.isEmpty {
            roles = member.roles.joined(separator: ",")
        }
    }
}

class CommunityMemberViewModel: ObservableObject {
    
    let communityId: String
    let commParticipation: AmityCommunityParticipation
    let commModeration: AmityCommunityModeration
    
    var token: AmityNotificationToken?
    var roleToFilter: String = ""
    
    @Published var roleUpdateStatus = ""
    @Published var permissionStatus = ""
    @Published var members: [CommunityMember] = []
    
    init(communityId: String) {
        self.communityId = communityId
        self.commParticipation = AmityCommunityParticipation(client: AmityManager.shared.client!, andCommunityId: communityId)
        self.commModeration = AmityCommunityModeration(client: AmityManager.shared.client!, andCommunity: communityId)
    }
    
    func addRoles(roles: [String], userId: String) {
        self.commModeration.addRoles(roles, userIds: [userId]) { [weak self] (success, error) in
            self?.roleUpdateStatus = success ? "Role Added" : "Error"
        }
    }
    
    func removeRoles(roles: [String], userId: String) {
        self.commModeration.removeRoles(roles, userIds: [userId]) { [weak self] (success, error) in
            self?.roleUpdateStatus = success ? "Role Removed" : "Error"
        }
    }
    
    func checkPermission(permission: AmityPermission) {
        AmityManager.shared.client?.hasPermission(permission, forCommunity: communityId, completion: { [weak self] hasPermission in
            self?.permissionStatus = hasPermission ? "Permission: True" : "Permission: False"
        })
    }
    
    func fetchFilteredMembers(roles: [String]) {
        self.members = []
        self.fetchMembers(roles: roles)
    }
    
    func fetchMembers(roles: [String]) {
        self.token = self.commParticipation.getMembers(membershipOptions: [.member], roles: roles, sortBy: .lastCreated).observe({ [weak self] (collection,_, error) in
            
            var list = [CommunityMember]()
            for member in collection.allObjects() {
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

extension AmityPermission {
    
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
        case .reviewCommunityPost:
            return "REVIEW COMMUNITY POST"
        default:
            return ""
        }
        
    }
}
