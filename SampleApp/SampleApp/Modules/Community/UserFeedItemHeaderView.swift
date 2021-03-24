//
//  UserFeedItemHeaderView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 7/21/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct UserFeedItemHeaderView: View {
    
    let id: Int
    let userName: String
    let date: String
    let isFlagged: Bool
    
    @State var showActionSheet = false
    
    @State var isDeleteSuccess = false
    @State var showDeleteAlert = false
    
    var body: some View {
        HStack {
            Image("feed_profile")
                .background(Color.gray)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text("\(self.userName) has shared this post")
                    .font(.subheadline)
                
                HStack {
                    Text(date)
                    .font(.caption)
                    .foregroundColor(Color.gray)
                    .padding(.top, 2)
                    
                    if self.isFlagged {
                        Text("Flagged")
                            .font(.caption)
                            .foregroundColor(Color.red)
                            .padding(.top, 2)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                self.showActionSheet = true
            }) {
                Image("ic_feed_action")
                    .frame(width: 44, height: 44, alignment: .center)
                    .aspectRatio(contentMode: .fit)
            }.buttonStyle(BorderlessButtonStyle())
                .actionSheet(isPresented: $showActionSheet) {
                    ActionSheet(title: Text(""), message: Text("What would you like to do?"), buttons: [
                        .default(Text("Comment")) {
                            Log.add(info: "Comment Button Tapped")
                        },
                        .default(Text("Edit")) {
                            Log.add(info: "Edit Button Tapped")
                        },
                        .default(Text("Delete")) {
                            
                        },
                        .default(Text("View Post")) {
                            Log.add(info: "View post button tapped")
                        },
                        .default(Text("Flag Post")) {
                            
                        },
                        .default(Text("UnFlag Post")) {
                            
                        },
                        .cancel()
                    ])
                    
            }
            .alert(isPresented: $showDeleteAlert) {
                let alertMessage = self.isDeleteSuccess ? "Post successfully deleted" : "Error while deleting post"
                return Alert(title: Text("Success"), message: Text(alertMessage), dismissButton: .default(Text("Dismiss")))
            }
        }
    }
}

struct UserFeedItemHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hey")
    }
}
