//
//  CommunityDetailView.swift
//  SampleApp
//
//  Created by Michael Abadi on 23/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct CommunityDetailView: View {
    
    @ObservedObject var viewModel: CommunityDetailViewModel
    
    init(viewModel: CommunityDetailViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            HeaderCard(isCreator: viewModel.community.isCreator,communityId: viewModel.community.communityId, image: Image("comm_header"), membersCount: viewModel.community.membersCount, displayName: viewModel.community.displayName, description: viewModel.community.description, postCount: viewModel.community.postsCount, isOfficial: viewModel.community.isOfficial, tags: viewModel.community.tags).padding()
            
            Button(action: {
                self.viewModel.queryFeed(sort: .lastCreated)
            }, label: {
                Text("Show community Feed")
            })
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            List {
                ForEach(viewModel.feed) { post  in
                    UserFeedItemView(model: post)
                        .padding([.top, .bottom], 8)
                }
            }
        }
        .navigationBarTitle("Detail", displayMode: .inline)
    }
}

struct HeaderCard: View {
    
    var isCreator: Bool
    var communityId: String
    var image: Image
    var membersCount: Int
    var displayName: String
    var description: String
    var postCount: Int
    var isOfficial: Bool
    var tags: [String]
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 6) {
                
                Text("\(self.isOfficial ? "Is Official":"Not Official")")
                    .fontWeight(Font.Weight.medium)
                    .font(Font.system(size: 14))
                    .foregroundColor(Color.white)
                    .padding([.leading, .trailing], 16)
                    .padding([.top, .bottom], 8)
                    .background(Color.black)
                    .cornerRadius(4)
                
                Text(self.displayName)
                    .font(.body)
                    .fontWeight(Font.Weight.heavy)
                
                if !self.description.isEmpty {
                    Text(self.description)
                        .font(.body)
                        .foregroundColor(Color.gray)
                }
                
                if !self.tags.isEmpty {
                    HStack(alignment: .center, spacing: 6) {
                        Text("Based on:")
                            .font(Font.system(size: 13))
                            .fontWeight(Font.Weight.heavy)
                        HStack {
                            ForEach(self.tags.indices, id: \.self) { index in
                                Text(self.tags[index])
                                    .font(Font.custom("HelveticaNeue-Medium", size: 12))
                                    .padding([.leading, .trailing], 10)
                                    .padding([.top, .bottom], 5)
                                    .foregroundColor(Color.white)
                            }
                        }
                        .background(Color(red: 43/255, green: 175/255, blue: 187/255))
                        .cornerRadius(7)
                        Spacer()
                    }
                    
                    .padding([.top, .bottom], 8)
                }
                
                HStack(alignment: .center, spacing: 0) {
                    Text("Post Count-")
                        .foregroundColor(Color.gray)
                    Text("\(self.postCount)")
                }.font(Font.custom("HelveticaNeue", size: 14))
                
                Divider()
                
                NavigationLink(destination: CommunityMemberView(communityId: communityId)) {
                    HStack(alignment: .center, spacing: 4) {
                        Text("\(self.membersCount)")
                            .fontWeight(Font.Weight.heavy)
                        Text("members join this community")
                            .font(Font.system(size: 13))
                            .fontWeight(Font.Weight.bold)
                            .foregroundColor(Color.gray)
                        Spacer()
                    }.padding([.top, .bottom], 8)
                }
            }
            .padding(12)
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.2), radius: 7, x: 0, y: 2)
    }
}
