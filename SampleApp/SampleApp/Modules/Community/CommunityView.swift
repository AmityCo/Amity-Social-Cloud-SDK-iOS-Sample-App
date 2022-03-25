//
//  CommunityView.swift
//  SampleApp
//
//  Created by Michael Abadi on 10/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI
import AmitySDK

struct CommunityView: View {
    
    @ObservedObject var viewModel: CommunityListViewModel
    @Environment(\.navigationController) var navigationController
    // HACK: Temporary bcs observed object for replaced an index doesn't trigger the cell unless scroll out and in back
    @State var forceUpdate: Bool = false
    @State private var showingFilterSheet = false
    @State private var showingSortSheet = false
    @State private var showCategoryListScreen = false
    @State private var showCreateScreen = false
    @State private var selection: String?
    @State var showUnableLeaveAlert = false
    
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
                
                
                HStack {
                    TextField("Search Here", text: $viewModel.searchKeyword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.searchCommunities()
                    }, label: {
                        Text("Search")
                    })
                }
                .padding([.leading, .trailing])
                
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
                        if selection == (community.id + "+feed") {
                            let feedManager = UserPostsFeedManager(client: AmityManager.shared.client!, userId: nil, userName: nil, community: community)
                            feedManager.feedType = .community
                            feedManager.community = community
                            
                            let postsFeedStoryboard = UIStoryboard(name: "Feed", bundle: nil)
                            let postsFeedController = postsFeedStoryboard.instantiateViewController(withIdentifier: UserPostsFeedViewController.identifier) as! UserPostsFeedViewController
                            postsFeedController.feedManager = feedManager
                            self.navigationController?.pushViewController(postsFeedController, animated: true)
                        }
                    }, realTimeEventAction: {
                        let eventController = CommunityRealTimeEventController()
                        let manager = CommunityRealTimeEventManager(community: community.communityObject)
                        eventController.manager = manager
                        
                        self.navigationController?.pushViewController(eventController, animated: true)
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
