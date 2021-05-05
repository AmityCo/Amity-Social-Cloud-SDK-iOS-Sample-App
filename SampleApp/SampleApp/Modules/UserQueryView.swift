//
//  UserQueryView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/5/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct UserQueryView: View {
    
    @State var userId = ""
    @State var userInfo = ""
    
    let viewModel = UserQueryViewModel()
    
    var body: some View {
        VStack {
            TextField("Enter User Id", text: $userId)
                .padding()
                .frame(height: 50)
                .background(Color(UIColor.systemGroupedBackground))
            
            Button(action: {
                self.viewModel.fetchUserInfo(id: self.userId) { info in
                    self.userInfo = info
                }
            }) {
                Text("Query User")
            }
            .frame(width: 200, height: 40)
            .foregroundColor(Color.white)
            .background(Color.blue)
            .cornerRadius(16)
            .padding(.top, 20)
            
            Button(action: {
                self.viewModel.fetchUserAvatar { imageData in
                    self.userInfo = self.userInfo + imageData
                }
            }) {
                Text("Test Avatar")
            }
            .frame(width: 200, height: 40)
            .foregroundColor(Color.white)
            .background(Color.blue)
            .cornerRadius(16)
            .padding(.top, 20)
            
            Text("Test if avatar is mapped correctly to this user.").font(.callout)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .padding(.top, 8)
            
            Text(userInfo)
                .padding(.top, 16)
            
            Spacer()
        }.padding()
            .navigationBarTitle("Individual User", displayMode: .inline)
        
    }
}

struct UserQueryView_Previews: PreviewProvider {
    static var previews: some View {
        UserQueryView()
    }
}

class UserQueryViewModel {
    
    var token: AmityNotificationToken?
    var fetchedUser: AmityObject<AmityUser>?
    
    let userRepo = AmityUserRepository(client: AmityManager.shared.client!)
    
    func fetchUserInfo(id: String, completion:@escaping (String) -> Void) {
        
        fetchedUser = userRepo.getUser(id)
        token = fetchedUser?.observe { (user, error) in
            
            let dataStatus = user.dataStatus == .local ? "Local" : "Fresh"
            
            if let err = error {
                completion("Error Occurred: \(err.localizedDescription) Data Status: \(dataStatus)")
            } else {
                let userId = user.object?.userId ?? ""
                let displayName = user.object?.displayName ?? ""
                let avatarFileId = user.object?.avatarFileId ?? ""
                let avatarUrl = user.object?.avatarCustomUrl ?? ""
                let metadata = user.object?.metadata?.description ?? ""
                let roles = (user.object?.roles as? [String])?.joined(separator: ",") ?? ""
                
                let info =
                """
                Data Status: \(dataStatus)
                UserId: \(userId)
                Display Name: \(displayName)
                AvatarFileId: \(avatarFileId)
                AvatarFileUrl: \(avatarUrl)
                Metadata: \(metadata)
                Roles: \(roles)
                """
                
                completion(info)
            }
        }
    }
    
    func fetchUserAvatar(completion: @escaping (String) -> Void) {
        guard let user = fetchedUser else { return }
        
        let avatarData = user.object?.getAvatarInfo()
        if let imageData = avatarData {
            let fileId = imageData.fileId
            let fileAttributes = imageData.attributes.description
            
            let fileInfo =
            """
            Mapped Data:
            
            FileId: \(fileId)
            Attributes: \(fileAttributes)
            """
            
            completion(fileInfo)
        } else {
            completion("\n\nThis user doesnot contains any avatar")
        }
    }
}
