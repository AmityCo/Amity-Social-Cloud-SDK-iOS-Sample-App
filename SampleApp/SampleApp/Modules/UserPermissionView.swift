//
//  UserPermissionView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 12/17/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct UserPermissionView: View {
    
    @ObservedObject var viewModel: UserPermissionViewModel
    @State var selectedPermission: Int = 0
    
    init(channelId: String?) {
        viewModel = UserPermissionViewModel(channelId: channelId ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Permissions")) {
                Picker(selection: $selectedPermission, label: Text("Select Permission")) {
                    ForEach(0..<SDKPermission.permissions.count, id: \.self) { i in
                        Text(SDKPermission.permissions[i].identifier)
                    }
                }
                
                Button("Check Permission") {
                    self.viewModel.checkPermission(permission: SDKPermission.permissions[selectedPermission])
                }
                
                Text("Result: \(viewModel.permissionStatus)")
                    .foregroundColor(Color.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct UserPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        UserPermissionView(channelId: nil)
    }
}

class UserPermissionViewModel: ObservableObject {
    
    var channelId: String = ""
    @Published var permissionStatus: String = ""
    
    init(channelId: String) {
        self.channelId = channelId
    }
    
    func checkPermission(permission: AmityPermission) {
        if channelId.isEmpty {
            AmityManager.shared.client?.hasPermission(permission, completion: { [weak self] hasPermission in
                self?.permissionStatus = hasPermission ? "Permission: True" : "Permission: False"
            })
        } else {
            AmityManager.shared.client?.hasPermission(permission, forChannel: channelId, completion: { [weak self] hasPermission in
                self?.permissionStatus = hasPermission ? "Permission: True" : "Permission: False"
            })
        }
    }
}

struct SDKPermission {
    
    static var permissions: [AmityPermission] = {
        let values: [AmityPermission] = [
            .muteChannel,
            .closeChannel,
            .editChannel,
            .editChannelRateLimit,
            .editMessage,
            .deleteMessage,
            .banChannelUser,
            .muteChannelUser,
            .addChannelUser,
            .removeChannelUser,
            .editChannelUser,
            .banUser,
            .editUser,
            .assignUserRole,
            .editUserFeedPost,
            .deleteUserFeedPost,
            .editUserFeedComment,
            .deleteUserFeedComment,
            .addCommunityUser,
            .removeCommunityUser,
            .editCommunityUser,
            .banCommunityUser,
            .muteCommunityUser,
            .editCommunity,
            .deleteCommunity,
            .editCommunityPost,
            .deleteCommunityPost,
            .pinCommunityPost,
            .editCommunityComment,
            .deleteCommunityComment,
            .reviewCommunityPost
        ]
        return values
    }()
    
}
