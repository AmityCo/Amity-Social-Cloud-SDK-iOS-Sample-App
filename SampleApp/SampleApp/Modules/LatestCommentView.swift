//
//  LatestCommentView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 3/4/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import SwiftUI

struct LatestCommentView: View {
    @State var referenceId: String = ""
    @State var selectedReferenceType: String = EkoCommentReferenceType.post.identifier
    @State var shouldIncludeReplies: Bool = false
    
    @ObservedObject var viewModel = LatestCommentViewModel()
    
    var referenceTypes: [String] = [EkoCommentReferenceType.post.identifier, EkoCommentReferenceType.content.identifier]
    
    var body: some View {
        Form {
            Section(header: Text("Create Comment")) {
                TextField("Enter Post/Content Id", text: $referenceId)
                Toggle("Include Replies", isOn: $shouldIncludeReplies)
                
                Picker("Reference Type", selection: $selectedReferenceType) {
                    ForEach(referenceTypes, id: \.self) { item in
                        Text(item)
                    }
                }
            }
            
            Section {
                Button(action: {
                    viewModel.getLatestComment(referenceId: referenceId, referenceType: selectedReferenceType, includeReplies: shouldIncludeReplies)
                }, label: {
                    HStack {
                        Spacer()
                        Text("Get Latest Comment")
                        Spacer()
                    }
                })
            }
            
            Section(header: Text("Here you will see local & server result received from sdk")) {
                VStack(alignment: .leading) {
                    Text("Local Result")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .padding(.bottom, 12)
                    Text(viewModel.localOutput)
                }
                
                VStack(alignment: .leading) {
                    Text("Server Result")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .padding(.bottom, 12)
                    Text(viewModel.serverOutput)
                }
            }
        }
        .navigationBarTitle("Latest Comment", displayMode: .inline)
    }
}

struct LatestCommentView_Previews: PreviewProvider {
    static var previews: some View {
        LatestCommentView()
    }
}

class LatestCommentViewModel: ObservableObject {
    
    var token: EkoNotificationToken?
    var commentRepo: EkoCommentRepository = EkoCommentRepository(client: EkoManager.shared.client!)
    
    @Published var localOutput = ""
    @Published var serverOutput = ""
    
    func getLatestComment(referenceId: String, referenceType: String, includeReplies: Bool) {
        let actualType: EkoCommentReferenceType = EkoCommentReferenceType.post.identifier == referenceType ? .post : .content
        token = commentRepo.getLatestComment(withReferenceId: referenceId, referenceType: actualType, includeReplies: includeReplies).observe({ (liveObject, error) in
            let dataStatus = liveObject.dataStatus.description
            
            guard let liveComment = liveObject.object else {
                
                let dataToPrint = """
                Data Status: \(dataStatus)
                Error: \(String(describing: error))
                
                Result: There is no latest comment.
                """
                
                if liveObject.dataStatus == .local {
                    self.localOutput = dataToPrint
                } else {
                    self.serverOutput = dataToPrint
                }
                
                return
                
            }
            
            let commentSyncState = liveComment.syncState.description
            let commentData = liveComment.data
            let commentId = liveComment.commentId
            let commentUserId = liveComment.userId
            
            let dataToPrint = """
            Data Status: \(dataStatus)
            Sync State: \(commentSyncState)
            Error: \(String(describing: error))

            ...

            Comment Data: \(commentData ?? [:])
            Comment Id: \(commentId)
            Comment User Id: \(commentUserId)
            """
            
            if liveObject.dataStatus == .local {
                self.localOutput = dataToPrint
            } else {
                self.serverOutput = dataToPrint
            }
        })
    }
}
