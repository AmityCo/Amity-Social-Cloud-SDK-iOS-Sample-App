//
//  CommunityCategoryListView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 8/3/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct CommunityCategoryListView: View{
    
    @ObservedObject var viewModel: CommunityListViewModel
    
    enum FilterType {
        case sort
        case isDeleted
    }
    
    @State var showActionSheet = false
    @State var actionSheetFilter: FilterType = .sort
    @State var sortedBy: String = "Display Name"
    @State var shouldIncludeDeleted: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                
                Button(action: {
                    self.actionSheetFilter = .sort
                    self.showActionSheet.toggle()
                }) {
                    HStack {
                        Text("Sorted By → \(sortedBy)")
                            .foregroundColor(Color.red)
                            .font(.system(size: 16, weight: .semibold))
                    }.padding([.top, .leading], 15)
                }
                
                Button(action: {
                    self.actionSheetFilter = .isDeleted
                    self.showActionSheet.toggle()
                }) {
                    HStack {
                        Text("Include Deleted Categories → \(shouldIncludeDeleted ? "YES" : "NO" )")
                            .foregroundColor(Color.blue)
                            .font(.system(size: 16, weight: .semibold))
                    }.padding([.top, .leading], 15)
                }
                
                List(viewModel.categories) { category in
                    VStack(alignment: .leading) {
                        Text("Name: \(category.name)")
                            .padding(.top, 4)
                        Text("Id: \(category.id)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        Text("Avatar: \(category.fileId)")
                            .asDescription()
                    }
                }
            }
            .navigationBarTitle("Community Categories", displayMode: .inline)
        }
        .onAppear {
            self.viewModel.queryAllCategories()
        }
        .actionSheet(isPresented: $showActionSheet, content: { () -> ActionSheet in
            if self.actionSheetFilter == .isDeleted {
                return ActionSheet(title: Text(""), message: Text("Sort Categories"), buttons: [
                    
                    .default(Text("Include Deleted Categories"), action: {
                        self.shouldIncludeDeleted = true
                        self.viewModel.shouldIncludeDeletedCategories = true
                        self.viewModel.reloadCategories()
                    }),
                    .default(Text("Don't include deleted categories"), action: {
                        self.shouldIncludeDeleted = false
                        self.viewModel.shouldIncludeDeletedCategories = false
                        self.viewModel.reloadCategories()
                    }),
                    .cancel()
                ])
            } else {
                return ActionSheet(title: Text(""), message: Text("Sort Categories"), buttons: [
                    
                    .default(Text("Display Name"), action: {
                        self.viewModel.sortCategories(sortOption: .displayName)
                        self.sortedBy = "Display Name"
                    }),
                    .default(Text("First Created"), action: {
                        self.viewModel.sortCategories(sortOption: .firstCreated)
                        self.sortedBy = "First Created"
                    }),
                    .default(Text("Last Created"), action: {
                        self.viewModel.sortCategories(sortOption: .lastCreated)
                        self.sortedBy = "Last Created"
                    }),
                    .cancel()
                ])
            }
        })
    }
}

struct CommunityCategoryListView_Previews: PreviewProvider {
    static var vm = CommunityListViewModel(type: .normal)
    
    static var previews: some View {
        CommunityCategoryListView(viewModel: vm)
    }
}


struct DescriptionStyle: ViewModifier {
    
    func body(content: Content) -> some View {
        return content
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(.top, 2)
    }
}

extension View {
    
    func asDescription() -> some View {
        return self.modifier(DescriptionStyle())
    }
}
