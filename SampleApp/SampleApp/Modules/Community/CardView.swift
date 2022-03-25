//
//  CardView.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 11/8/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import SwiftUI

struct CardView: View {
    typealias Action = (() -> Void)?
    
    var model: CommunityListModel
    var deleteAction: (() -> Void)?
    var leaveAction: (() -> Void)?
    var detailsAction: (() -> Void)?
    var joinAction: (() -> Void)?
    var updateAction: (() -> Void)?
    var membershipAction: (() -> Void)?
    var feedAction: (() -> Void)?
    var realTimeEventAction: (() -> Void)?
    
    @State var showAction: Bool = false
    
    init(model: CommunityListModel,
         joinAction: Action,
         leaveAction: Action,
         deleteAction: Action,
         detailsAction: Action,
         updateAction: Action,
         membershipAction: Action,
         feedAction: Action,
         realTimeEventAction: Action) {
        self.model = model
        self.joinAction = joinAction
        self.leaveAction = leaveAction
        self.deleteAction = deleteAction
        self.detailsAction = detailsAction
        self.updateAction = updateAction
        self.membershipAction = membershipAction
        self.feedAction = feedAction
        self.realTimeEventAction = realTimeEventAction
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(model.displayName)")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.top, 12)

                    if !model.description.isEmpty {
                        Text("\(model.description.capitalized)")
                            .foregroundColor(Color.white.opacity(0.9))
                            .padding(.top, 4)
                            .font(.body)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                Image(systemName: "ellipsis.circle")
                    .resizable()
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .padding()
                    .onTapGesture {
                        self.showAction.toggle()
                    }
                .actionSheet(isPresented: $showAction, content: {
                    ActionSheet(title: Text("Choose Actions"), message: Text("What do you want to do?"), buttons: getAllActions())
                })
            }

            VStack(spacing: 5) {

                let data = model.getPreviewData()

                ForEach(0..<data.count, id: \.self) { index in
                    let item = data[index]
                    CardTextView(key: item.0, value: item.1)
                }

            }
            .padding([.top, .bottom], 16)
        }
        .background(model.isJoined ? Color("NeonGreen") : Color("PastelBlue"))
        .cornerRadius(20)
        .shadow(color: Color.gray.opacity(0.6), radius: 8, x: 0, y: 0)
        .padding([.top, .bottom], 8)
    }
    
    func getAllActions() -> [ActionSheet.Button] {
        var actions = [ActionSheet.Button]()
        
        if model.isJoined {
            actions.append(.default(Text("View Community Details"), action: {
                detailsAction?()
            }))
            
            actions.append(.default(Text("View Community Feed"), action: {
                feedAction?()
            }))
            
            actions.append(.default(Text("Leave Community"), action: {
                leaveAction?()
            }))
            
            actions.append(.default(Text("Real Time Event"), action: {
                realTimeEventAction?()
            }))
            
            // Actions related to creator
            if model.isCreator {
                actions.append(.default(Text("Add/Remove Members"), action: {
                    membershipAction?()
                }))
                
                actions.append(.default(Text("Update Community"), action: {
                    updateAction?()
                }))
                
                actions.append(.default(Text("Delete Community"), action: {
                    deleteAction?()
                }))
            }
        } else {
            actions.append(.default(Text("Join Community"), action: {
                joinAction?()
            }))
        }
        
        // Default dismiss action
        actions.append(.cancel(Text("Dismiss")))
        
        return actions
    }
}
