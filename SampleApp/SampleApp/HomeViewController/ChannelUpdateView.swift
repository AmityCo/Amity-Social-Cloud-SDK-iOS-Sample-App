//
//  ChannelUpdateView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/1/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct ChannelUpdateView: View {
    
    @State var displayName = ""
    @State var metadataKey = ""
    @State var metadataValue = ""
    @State var tags = ""
    @State var shouldRemoveAvatar = false
    @State var channelId = ""
    
    @State var selectedImage: UIImage?
    @State var shouldShowImagePicker = false
    
    @ObservedObject var viewModel = ChannelUpdateViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("Channel Id")) {
                TextField("-", text: $channelId)
            }
            
            Section(header: Text("Display Name")) {
                TextField("-", text: $displayName)
            }
            
            Section(header: Text("Metadata"), footer: Text("Add keys & value separated by comma")) {
                TextField("Key", text: $metadataKey)
                TextField("Value", text: $metadataValue)
            }
            
            Section(header: Text("Tags"), footer: Text("Add tags separated by comma")) {
                TextField("-", text: $tags)
            }
            
            Toggle(isOn: $shouldRemoveAvatar) {
                Text("Remove Avatar")
            }
            
            Button(action: {
                self.shouldShowImagePicker = true
            }) {
                Text("Add Avatar")
            }
            .sheet(isPresented: $shouldShowImagePicker) {
                return SwiftUIImagePicker(image: self.$selectedImage)
            }
            
            Text(viewModel.channelUpdateStatus)
                .foregroundColor(Color.red)
                .multilineTextAlignment(.center)
            
        }
        .navigationBarTitle("Update Channel", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            
            self.viewModel.updateChannel(id:self.channelId, displayName: self.displayName, metadataKey: self.metadataKey, metadataValue: self.metadataValue, shouldRemoveAvatar: self.shouldRemoveAvatar, selectedAvatar: self.selectedImage)
            
        }, label: {
            Text("Apply")
        }))
    }
}

struct ChannelUpdateView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelUpdateView()
    }
}
