//
//  UserFeedItemView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 7/17/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct UserFeedItemView: View {
    
    var model: CommunityPostModel
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            UserFeedItemHeaderView(id: 1, userName: model.postedUserDisplayName ?? "Some user", date: "Now", isFlagged: false)
            
            Text(model.text ?? "Some content")
            .font(.subheadline)
            .foregroundColor(Color.primary)
            .padding([.top], 8)
            
            Text("Like")
            .font(.subheadline)
            .foregroundColor(Color.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            
            Divider()
                .padding(.top, 8)
            
            HStack {
                
                ReactionView(reactionTitle: "Like", reactionImage: Image("feed_like"), reactHandler: {
                    
                })
                
                Divider()
                    .frame(height: 16)
                
                ReactionView(reactionTitle: "Love", reactionImage: Image("feed_love"), reactHandler: {
                    
                })
            }
        }
        .padding(16)
        .background(Color.white)
    }
}

struct ReactionView: View {
    
    let reactionTitle: String
    let reactionImage: Image
    let reactHandler: () -> Void
    
    var body: some View {
        Button(action: {
            self.reactHandler()
        }) {
            HStack {
                Spacer()
                reactionImage
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color.gray)
                    .frame(width: 18, height: 18)
                    .padding(.trailing, 8)
                Text(reactionTitle)
                    .foregroundColor(Color.primary)
                Spacer()
            }.padding(.top, 8)
        }.buttonStyle(BorderlessButtonStyle())
    }
}
