//
//  ChannelUpdateViewModel.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/1/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation

class ChannelUpdateViewModel: ObservableObject {
    
    var channelRepo: AmityChannelRepository?
    var fileRepo: AmityFileRepository?
    
    var token: AmityNotificationToken?
    
    @Published var channelUpdateStatus = ""
    
    func updateChannel(id: String, displayName: String, metadataKey: String, metadataValue: String, shouldRemoveAvatar: Bool, selectedAvatar: UIImage?) {
       
        guard !id.isEmpty else {
            channelUpdateStatus = "Channel Id cannot be empty"
            return
        }
        
        self.channelUpdateStatus = "Updating channel..."
        
        let keys = metadataKey.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ",")
        let values = metadataValue.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ",")
        
        self.channelRepo = AmityChannelRepository(client: AmityManager.shared.client!)
        self.fileRepo = AmityFileRepository(client: AmityManager.shared.client!)
        
        let channelUpdater = AmityChannelUpdateBuilder(id: id, andClient: AmityManager.shared.client!)
        
        if shouldRemoveAvatar {
            channelUpdater.setAvatar(nil)
        }
        
        if !displayName.isEmpty {
            channelUpdater.setDisplayName(displayName)
        }
        
        if !keys.isEmpty {
            var metadata = [String: String]()
            for (index, key) in keys.enumerated() {
                metadata[key] = values[index]
            }
            
            if !metadata.isEmpty {
                channelUpdater.setMetadata(metadata)
            }
        }
        
        if let avatar = selectedAvatar {
            channelUpdateStatus = "In Progress..."
            fileRepo?.uploadImage(avatar, progress: nil, completion: { [weak self] (imageData, error) in
                
                channelUpdater.setAvatar(imageData)
                self?.updateChannel(updater: channelUpdater)
            })
        } else {
            channelUpdateStatus = "In Progress..."
            updateChannel(updater: channelUpdater)
        }
    }
    
    func updateChannel(updater: AmityChannelUpdateBuilder) {
        token = updater.update().observe({ [weak self] (channel, error) in
            self?.token?.invalidate()
            
            if let err = error {
                self?.channelUpdateStatus = "Error: Check if you have permission to update"
                Log.add(info: "Update Error: \(err)")
            } else {
                self?.channelUpdateStatus = "Channel Updated!!"
            }
        })
    }
}
