//
//  CommunityMemberView.swift
//  SampleApp
//
//  Created by Michael Abadi on 07/08/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI
import EkoChat

struct CommunityMemberView: View {
    
    @ObservedObject var viewModel: CommunityMemberViewModel
    @State var roleTitle: String = ""
    
    init(communityId: String) {
        viewModel = CommunityMemberViewModel(communityId: communityId)
    }
    
    var body: some View {
        VStack {
            
            HStack {
                TextField("Enter Role", text: $roleTitle)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Spacer()
                Button("Filter") {
                    let enteredRoles = roleTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    let roles = enteredRoles.isEmpty ? [] : enteredRoles.components(separatedBy: ",")
                    viewModel.fetchFilteredMembers(roles: roles)
                }
            }.padding()
            
            Text("You can also enter multiple roles separated by comma i.e ,")
                .font(.caption)
            
            List(viewModel.members, id: \.id) { m in
                NavigationLink(
                    destination: CommunityRoleView(viewModel: viewModel, userId: m.id),
                    label: {
                        VStack(alignment: .leading) {
                            Text("\(m.title)")
                            Text("Role: \(m.roles)")
                                .font(.body)
                                .padding(.top, 2)
                                .foregroundColor(Color.secondary)
                        }
                    })
            }
        }
        .onAppear(perform: {
            viewModel.fetchMembers(roles: [])
        })
    }
}

struct CommunityMemberView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityMemberView(communityId: "")
    }
}

struct CommunityRoleView: View {
    @State var role: String = ""
    @State var selectedPermission: Int = 0
    
    let viewModel: CommunityMemberViewModel
    let userId: String
    
    init(viewModel: CommunityMemberViewModel, userId: String) {
        self.viewModel = viewModel
        self.userId = userId
    }
    
    var body: some View {
        Form {
            Section(header: Text("Roles")) {
                TextField("Enter role", text: $role)
                    .autocapitalization(.none)
                
                Button("Assign Role") {
                    self.viewModel.addRole(role: role, userId: userId)
                }
                
                Button("UnAssign Role") {
                    self.viewModel.removeRole(role: role, userId: userId)
                }
                
                Text("Result: \(viewModel.roleUpdateStatus)")
                    .foregroundColor(Color.red)
                    .multilineTextAlignment(.center)
            }
            
            Section(header: Text("Permissions"), footer: Text("This checks permissions for current logged in user")) {
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
        }.onAppear(perform: {
            viewModel.resetStatus()
        })
    }
}
