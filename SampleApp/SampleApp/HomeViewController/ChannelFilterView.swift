//
//  ChannelFilterView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 9/29/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct ChannelFilterView: View {
    
    var channelTypes: [AmityChannelType] = AmityChannelType.allCases
    var filterTypes: [AmityChannelQueryFilter] = [.all, .userIsMember, .userIsNotMember]
    
    @State var includedTags = UserDefaults.standard.includingTags.joined(separator: ",")
    @State var excludedTags = UserDefaults.standard.excludingTags.joined(separator: ",")
    @State var selectedChannelTypeIndex: Int = Int(UserDefaults.standard.channelTypeFilter.rawValue)
    @State var selectedFilterTypeIndex: Int = UserDefaults.standard.filter.rawValue
    
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        Form {
            Section(header: Text("Select Channels:")) {
                Picker(selection: $selectedChannelTypeIndex, label: Text("Channel")) {
                    ForEach(0..<channelTypes.count, id: \.self) { i in
                        Text(self.channelTypes[i].description)
                    }
                }
            }
            
            Section(header: Text("Filter Channels By:")) {
                Picker(selection: $selectedFilterTypeIndex, label: Text("Filter")) {
                    ForEach(0..<filterTypes.count, id: \.self) { i in
                        Text(self.filterTypes[i].description)
                    }
                }
            }
            
            Section(header: Text("Tags:"), footer: Text("Add tags separated by comma")) {
                VStack(alignment: .leading) {
                    Text("Including Tags:")
                        .font(.callout)
                        .foregroundColor(Color(.secondaryLabel))
                    TextField("-", text: $includedTags)
                        .frame(height: 35)
                    Divider()
                    Text("Excluding Tags:")
                        .font(.callout)
                        .foregroundColor(Color(.secondaryLabel))
                    TextField("-", text: $excludedTags)
                        .frame(height: 35)
                }
            }
        }.navigationBarTitle("Channel Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                
                Log.add(info: "Selected Channel Type: \(self.channelTypes[Int(self.selectedChannelTypeIndex)])")
                
                // Just save selected options in user defaults to be used later
                UserDefaults.standard.channelTypeFilter = self.channelTypes[Int(self.selectedChannelTypeIndex)]
                UserDefaults.standard.filter = self.filterTypes[Int(self.selectedFilterTypeIndex)]
                
                let incTags = self.includedTags.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter{ !$0.isEmpty }
                let excTags = self.excludedTags.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter{ !$0.isEmpty }
                
                UserDefaults.standard.includingTags = incTags
                UserDefaults.standard.excludingTags = excTags
                
                self.presentation.wrappedValue.dismiss()
            }, label: {
                Text("Apply")
            }))
    }
}

struct ChannelFilterView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelFilterView()
    }
}

extension AmityChannelType: CaseIterable {
    
    public static var allCases: [AmityChannelType] {
        return [.standard, .private, .broadcast, .conversation, .live, .community, .unknown]
    }
    
}
