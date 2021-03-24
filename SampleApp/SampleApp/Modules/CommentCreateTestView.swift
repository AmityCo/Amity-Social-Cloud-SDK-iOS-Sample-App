//
//  CommentCreateTestView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 2/24/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import SwiftUI

struct CommentCreateTestView: View {
    
    @State var referenceId: String = ""
    @State var commentText: String = ""
    @State var selectedReferenceType: String = ""
    
    @ObservedObject var viewModel = CreateCommentTestViewModel()
    
    var referenceTypes: [String] = [EkoCommentReferenceType.post.identifier, EkoCommentReferenceType.content.identifier]
    
    var body: some View {
        Form {
            Section(header: Text("Create Comment")) {
                TextField("Enter Post/Content Id", text: $referenceId)
                TextField("Enter comment", text: $commentText)
                Picker("Reference Type", selection: $selectedReferenceType) {
                    ForEach(referenceTypes, id: \.self) { item in
                        Text(item)
                    }
                }
            }
            
            Section {
                Button(action: {
                    viewModel.createComment(contentId: referenceId, comment: commentText, referenceType: selectedReferenceType)
                }, label: {
                    HStack {
                        Spacer()
                        Text("Create")
                        Spacer()
                    }
                })
            }
            
            Section(header: Text("Here you will see local & server result received from sdk after creation")) {
                VStack(alignment: .leading) {
                    Text("Local Result")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                    Text(viewModel.localOutput)
                }
                
                VStack(alignment: .leading) {
                    Text("Server Result")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                    Text(viewModel.serverOutput)
                }
            }
        }
        .navigationBarTitle("Comment Test", displayMode: .inline)
    }
}

struct CommentCreateTestView_Previews: PreviewProvider {
    static var previews: some View {
        CommentCreateTestView()
    }
}

class CreateCommentTestViewModel: ObservableObject {
    
    var commentRepo: EkoCommentRepository = EkoCommentRepository(client: EkoManager.shared.client!)
    var token: EkoNotificationToken?
    
    @Published var localOutput = ""
    @Published var serverOutput = ""
    
    func createComment(contentId:String, comment: String, referenceType: String) {
        let actualType: EkoCommentReferenceType = EkoCommentReferenceType.post.identifier == referenceType ? .post : .content
        token = commentRepo.createComment(withReferenceId: contentId, referenceType: actualType , parentId: nil, text: comment).observe({ [weak self] (liveObject, error) in
            let dataStatus = liveObject.dataStatus.description
            
            guard let liveComment = liveObject.object else { return }
            
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
                self?.localOutput = dataToPrint
            } else {
                self?.serverOutput = dataToPrint
            }
        })
    }
}

extension EkoCommentReferenceType {
    
    var identifier: String {
        switch self {
        case .post:
            return "Post"
        case .content:
            return "Content"
        default:
            return ""
        }
    }
}
