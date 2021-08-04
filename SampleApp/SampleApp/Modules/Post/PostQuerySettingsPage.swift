//
//  PostQuerySettingsViewController.swift
//  SampleApp
//
//  Created by Nutchaphon Rewik on 21/7/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct PostQuerySettingsPage: View{
    
    @State var targetType = AmityPostTargetType.user
    @State var targetId: String = ""
    @State var sortBy = AmityPostQuerySortOption.lastCreated
    @State var isDeleted = AmityQueryOption.notDeleted
    
    @State var includesAllPostTypes = true {
        didSet {
            if includesAllPostTypes {
                filteredPostTypes.removeAll()
            }
        }
    }
    
    @State var filteredPostTypes: Set<String> = [] {
        didSet {
            if !filteredPostTypes.isEmpty {
                includesAllPostTypes = false
            }
        }
    }
    
    var body: some View {
        form()
            .navigationTitle("Query Settings")
    }
    
    private func form() -> some View {
        Form {
            Section(header: Text("General")) {
                Picker("Target Type", selection: $targetType) {
                    Text("User").tag(AmityPostTargetType.user)
                    Text("Community").tag(AmityPostTargetType.community)
                }
                HStack {
                    Text("targetId")
                    Spacer()
                    TextField("insert-id-here", text: $targetId)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.emailAddress)
                }
                Picker("Sort By", selection: $sortBy) {
                    Text("Last Created").tag(AmityPostQuerySortOption.lastCreated)
                    Text("First Created").tag(AmityPostQuerySortOption.firstCreated)
                }
                Picker("post.isDeleted", selection: $isDeleted) {
                    Text("isDeleted == false").tag(AmityQueryOption.notDeleted)
                    Text("isDeleted == true").tag(AmityQueryOption.deleted)
                    Text("any").tag(AmityQueryOption.all)
                }
            }
            Section(header: Text("Post Types")) {
                Toggle("All post types", isOn: $includesAllPostTypes)
                if !includesAllPostTypes {
                    List {
                        ForEach(["image", "video", "file"], id: \.self) { item in
                            MultipleSelectionRow(title: item, isSelected: filteredPostTypes.contains(item)) {
                                if filteredPostTypes.contains(item) {
                                    filteredPostTypes.remove(item)
                                } else {
                                    filteredPostTypes.insert(item)
                                }
                            }
                        }
                    }
                }
            }
            Section() {
                let options = AmityPostQueryOptions(
                    targetType: targetType,
                    targetId: targetId,
                    sortBy: sortBy,
                    deletedOption: isDeleted,
                    filterPostTypes: (includesAllPostTypes || filteredPostTypes.isEmpty) ? nil : filteredPostTypes
                )
                NavigationLink(destination: PostListPage(options: options)) {
                    Button("Query Posts") {
                        // Intentionally left empty
                    }
                }
            }
        }
    }
    
}

struct MultipleSelectionRow: View {
    
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isSelected {
                    Image(systemName: "checkmark").foregroundColor(.blue)
                }
                Text(title)
            }
        }.foregroundColor(Color.black)
    }
    
}

@available(iOS 14.0, *)
struct PostQuerySettingsViewController_Previews: PreviewProvider {
    
    static var previews: some View {
        PostQuerySettingsPage()
    }
    
}
