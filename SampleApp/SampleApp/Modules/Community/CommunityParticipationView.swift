//
//  CommunityParticipationView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/7/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct CommunityParticipationView: View {
    
    @State var userId: String = ""
    @State var message: String = ""
    
    var viewModel: CommunityParticipationViewModel
    
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        Form {
            Section(header: Text("User Ids:"), footer: Text("Enter user id separated by comma")) {
                TextField("", text: $userId)
            }
            
            Button(action: {
                let users: [String] = self.userId.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                self.viewModel.addUsers(users: users) { status in
                    self.message = status
                }
            }) {
                Text("Add User")
            }
            
            Button(action: {
                let users: [String] = self.userId.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                self.viewModel.removeUsers(users: users) { status in
                    self.message = status
                }
            }) {
                Text("Remove User")
            }
            
            Text(message)
            
        }.navigationBarTitle("User Participation", displayMode: .inline)
    }
}

struct CommunityParticipationView_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
    }
}

class CommunityParticipationViewModel {
    
    let participation: EkoCommunityParticipation
    
    init(participation: EkoCommunityParticipation) {
        self.participation = participation
    }
    
    func addUsers(users: [String], completion: @escaping (String) -> Void) {
        participation.addUsers(users) { (isSuccess, error) in
            completion(isSuccess ? "User added successfully" : "Error adding users")
        }
    }
    
    func removeUsers(users: [String], completion: @escaping (String) -> Void) {
        participation.removeUsers(users) { (isSuccess, error) in
            completion(isSuccess ? "User removed successfully" : "Error removing users")
        }
    }
}
