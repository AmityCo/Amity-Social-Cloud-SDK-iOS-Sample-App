//
//  CommunityDetailView.swift
//  SampleApp
//
//  Created by Michael Abadi on 23/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Combine
import SwiftUI

struct CommunityDetailView: View {
    
    @ObservedObject var viewModel: CommunityDetailViewModel
    
    init(viewModel: CommunityDetailViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            HeaderCard(isCreator: viewModel.community.isCreator,communityId: viewModel.community.communityId, image: Image("comm_header"), membersCount: viewModel.community.membersCount, displayName: viewModel.community.displayName, description: viewModel.community.description, postCount: viewModel.community.postsCount, isOfficial: viewModel.community.isOfficial, tags: viewModel.community.tags).padding()
            
            NotificationPanelView(viewModel: viewModel)
        }
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

struct NotificationPanelView: View {
    
    @State private var cancellables = Set<AnyCancellable>()
    
    @ObservedObject private var viewModel: CommunityDetailViewModel
    @State private var isEnabled: Bool = false
    @State private var toggleStatus: [Bool] = []
    @State private var isModeratorRole: Bool = false
    @State private var isLoaded = false
    
    var events: [CommunityNotificationEvent] {
        return viewModel.communityNotification?.events
            .filter({ $0.isNetworkEnabled }) ?? []
    }
    
    init(viewModel: CommunityDetailViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        DispatchQueue.main.async {
            viewModel.$communityNotification
                .sink(receiveValue: {
                    isEnabled = $0?.isPushEnabled ?? false
                    toggleStatus =  $0?.events.map { $0.isPushEnabled } ?? []
                    if $0?.events != nil && !isLoaded {
                        isModeratorRole = $0?.events.first(where: { $0.eventType == .postCreated })?.roles.contains("moderator") ?? false
                        isLoaded = true
                    }
                })
                .store(in: &cancellables)
        }
        
        return VStack(alignment: .center, spacing: 6) {
            
            Text("Notification settings").bold()
            Toggle("Notifications", isOn: $isEnabled)
            
            ForEach(0..<events.count, id: \.self) { index in
                if events[index].eventType == .postCreated {
                    VStack {
                        Toggle(events[index].tittle, isOn: $toggleStatus[index])
                        Button(action: {
                            isModeratorRole.toggle()
                        }) {
                            let roleTitle = isModeratorRole ? "Only Moderator" : "Everyone"
                            Text(roleTitle)
                        }
                    }.padding(.bottom)
                } else {
                    Toggle(events[index].tittle, isOn: $toggleStatus[index])
                }
            }
            
            Button("Save Settings") {
                var updatedEvents: [AmityCommunityNotificationEvent] = []
                for index in 0..<events.count {

                    var rolFilter: AmityRoleFilter? = nil
                    if events[index].eventType == .postCreated {
                        let roleIds = isModeratorRole ? ["moderator"] : []
                        rolFilter = .onlyFilter(withRoleIds: roleIds)
                    }
                    let event = AmityCommunityNotificationEvent(eventType: events[index].eventType, isEnabled: toggleStatus[index], roleFilter: rolFilter)
                    updatedEvents.append(event)
                }
                viewModel.updateNoticommunityRepositoryzfication(isPushEnabled: isEnabled, events: updatedEvents)
            }
            .padding(4)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .alert(isPresented: Binding<Bool>(
                get: { self.viewModel.showNotificationErrorAlert == true },
                set: { _ in self.viewModel.showNotificationErrorAlert = false }
            )) {
                return Alert(title: Text("Simething went wrong"), message: Text("Please enable notifications"), dismissButton: .default(Text("Ok")))
            }
        }
        
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.2), radius: 7, x: 0, y: 2)
    }
}
