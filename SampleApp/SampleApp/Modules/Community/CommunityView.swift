//
//  CommunityView.swift
//  SampleApp
//
//  Created by Michael Abadi on 10/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct CommunityView: View {
    
    @ObservedObject var viewModel: CommunityListViewModel
    
    // HACK: Temporary bcs observed object for replaced an index doesn't trigger the cell unless scroll out and in back
    @State var forceUpdate: Bool = false
    @State private var showingFilterSheet = false
    @State private var showingSortSheet = false
    @State private var showCategoryListScreen = false
    @State private var showCreateScreen = false
    @State private var selection: String?
    
    var body: some View {
        VStack {
            
            if viewModel.type == .normal {
                HStack {
                    
                    Button(action: {
                        self.showingFilterSheet.toggle()
                    }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .font(Font.system(.title))
                    }
                    .actionSheet(isPresented: $showingFilterSheet) {
                        ActionSheet(title: Text("How do you want to filter?"), message: Text("Filter options"), buttons: [
                            .default(Text("All"), action: {
                                self.viewModel.setFilter(.all)
                            }),
                            .default(Text("Member"), action: {
                                self.viewModel.setFilter(.userIsMember)
                            }),
                            .default(Text("Not Member"), action: {
                                self.viewModel.setFilter(.userIsNotMember)
                            }),
                            .cancel(Text("Dismiss"))
                        ]
                        )
                    }
                    Button(action: {
                        self.showingSortSheet.toggle()
                    }) {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(Font.system(.title))
                    }
                    .actionSheet(isPresented: $showingSortSheet) {
                        ActionSheet(title: Text("How do you want to sort?"), message: Text("Sort options"), buttons: [
                            .default(Text("First created"), action: {
                                self.viewModel.setSort(.firstCreated)
                            }),
                            .default(Text("Last created"), action: {
                                self.viewModel.setSort(.lastCreated)
                            }),
                            .default(Text("Display Name"), action: {
                                self.viewModel.setSort(.displayName)
                            }),
                            .cancel(Text("Dismiss"))
                        ])
                    }
                    
                    Button(action: {
                        self.showCategoryListScreen = true
                    }, label: {
                        Image(systemName: "list.bullet")
                    })
                    .sheet(isPresented: $showCategoryListScreen) {
                        return CommunityCategoryListView(viewModel: self.viewModel)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: CommunityEditorView(viewModel: CommunityEditorViewModel()), isActive: $showCreateScreen) {
                        Button(action: {
                            self.showCreateScreen = true
                        }, label: {
                            Image(systemName: "plus")
                        })
                    }
                }.padding()
                
                TextField("Search Here", text: $viewModel.searchKeyword)
                    .padding([.leading, .trailing, .top])
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            List(viewModel.community) { community in
                ZStack {
                    CardView(model: community, joinAction: {
                        self.viewModel.joinCommunity(for: community, completion: nil)
                    }, leaveAction: {
                        self.viewModel.leaveCommunity(for: community, completion: nil)
                    }, deleteAction: {
                        self.viewModel.deleteCommunity(for: community, completion: nil)
                    }, detailsAction: {
                        self.selection = community.id + "+detail"
                    }, updateAction: {
                        self.selection = community.id + "+edit"
                    }, membershipAction: {
                        self.selection = community.id + "+participation"
                    }, feedAction: {
                        self.selection = community.id + "+feed"
                    })
                    .onAppear {
                        if self.viewModel.community.last == community {
                            self.viewModel.fetchNextPage()
                        }
                    }
                    
                    // Update Navigattion
                    let editorView = CommunityEditorView(viewModel: CommunityEditorViewModel(draft: CommunityDraft(community: community)))
                    
                    NavigationLink(
                        destination: editorView,
                        tag: community.id + "+edit",
                        selection: self.$selection,
                        label: {
                            EmptyView()
                        })
                        .buttonStyle(PlainButtonStyle())
                        .hidden()
                    
                    // Participation Navigation
                    let participationModel = CommunityParticipationViewModel(participation: community.getCommunityObject().participation)
                    NavigationLink(
                        destination: CommunityParticipationView(viewModel: participationModel),
                        tag: community.id + "+participation",
                        selection: self.$selection,
                        label: {
                            EmptyView()
                        })
                        .buttonStyle(PlainButtonStyle())
                        .hidden()
                    
                    // Feed
                    NavigationLink(
                        destination: CommunityFeedViews(viewModel: CommunityFeedViewModel(community: community)),
                        tag: community.id + "+feed",
                        selection: self.$selection,
                        label: {
                            EmptyView()
                        })
                        .buttonStyle(PlainButtonStyle())
                        .hidden()
           
                    
                    // Details
                    NavigationLink(
                        destination: CommunityDetailView(viewModel: CommunityDetailViewModel(community: community)),
                        tag: community.id + "+detail",
                        selection: self.$selection,
                        label: {
                            EmptyView()
                        })
                        .buttonStyle(PlainButtonStyle())
                        .hidden()
                    
                }
            }
        }
        .navigationBarTitle(Text(viewModel.pageTitle), displayMode: .inline)
        .onAppear(perform: {
            self.selection = nil
            //self.showCategoryListScreen = false
            self.showCreateScreen = false
            
            self.forceUpdate.toggle()
            self.viewModel.queryCommunity()
            UITableViewCell.appearance().selectionStyle = .none
            UITableView.appearance().separatorStyle = .none
        })
        
    }
}

struct CommunitiesView_Previews: PreviewProvider {
    
    static var previews: some View {
        return Text("Community View")
    }
}

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
    
    @State var showAction: Bool = false
    
    init(model: CommunityListModel, joinAction: Action, leaveAction: Action, deleteAction: Action, detailsAction: Action, updateAction: Action, membershipAction: Action, feedAction: Action) {
        self.model = model
        self.joinAction = joinAction
        self.leaveAction = leaveAction
        self.deleteAction = deleteAction
        self.detailsAction = detailsAction
        self.updateAction = updateAction
        self.membershipAction = membershipAction
        self.feedAction = feedAction
    }
    
    var body: some View {
        VStack {

            // Header Title
            HStack {
                VStack(alignment: .leading) {
                    Text("\(model.displayName.capitalized)")
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
                
                Button(action: {
                    self.showAction.toggle()
                }, label: {
                    Image(systemName: "ellipsis.circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding()
                })
                .padding()
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

struct CardTextView: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(key)
                .padding(.leading, 20)
                .foregroundColor(Color.white)
                .font(.system(size: 15))
            
            Text(value)
                .foregroundColor(Color.white.opacity(0.8))
                .font(.system(size: 15))
                .lineLimit(1)
            
            Spacer()
        }
    }
}

struct ActionButtonStyle: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .padding([.leading, .trailing], 8)
            .padding([.top, .bottom], 8)
            .background(Color.black)
            .cornerRadius(4)
            .foregroundColor(Color.white)
    }
}
