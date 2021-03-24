//
//  ChannelDetailsView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/6/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct ChannelDetail {
    
    var channel: EkoChannel?
    var type: String = ""
    var metadata: String = ""
    var displayName: String = ""
    var isDistinct: Bool = true
    var memberCount: Int = 0
    var membership: String = ""
    var tags: String = ""
    var avatarFileId = ""
    
    init(object: EkoChannel) {
        channel = object
        type = object.channelType.description
        metadata = object.metadata?.description ?? ""
        displayName = object.displayName ?? "-"
        isDistinct = object.isDistinct
        memberCount = object.memberCount
        membership = object.currentUserMembership.description
        tags = (object.tags as? [String])?.joined(separator: ",") ?? ""
        avatarFileId = object.avatarFileId ?? ""
    }
    
    func getDetails() -> String {
        let info =
        """
        Channel Name: \(displayName)
        Type: \(type)
        MetaData: \(metadata)
        Tags: \(tags)
        Is Distinct: \(isDistinct)
        Member Count: \(memberCount)
        Is Current User Member: \(membership)
        Avatar File Id: \(avatarFileId)
        """
        
        return info
    }
    
    func fetchImageData(completion: @escaping (String) -> Void) {
        self.channel?.getAvatarInfo({ avatar in
            
            if let imageData = avatar {
                let fileId = imageData.fileId
                let attributes = imageData.attributes.description
                
                let fileInfo =
                """
                Mapped Data:
                
                FileId: \(fileId)
                Attributes: \(attributes)
                """
                completion(fileInfo)
            } else {
                completion("This user doesnot contain any avatar")
            }
        })
        
    }
    
    init() { /* For preview view */ }
}

struct ChannelDetailsView: View {
    
    var detail: ChannelDetail
    @State var avatarInfo: String = ""
    
    var body: some View {
        VStack {
            
            Text(detail.getDetails())
            Text(avatarInfo)
                .padding(.top, 12)
            
            Button(action: {
                self.detail.fetchImageData { info in
                    self.avatarInfo = info
                }
            }) {
                Text("Test Avatar")
            }
            .frame(width: 200, height: 40)
            .foregroundColor(Color.white)
            .background(Color.blue)
            .cornerRadius(16)
            .padding(.top, 20)
            
            Text("Test if avatar is mapped correctly to this channel.")
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .padding(.top, 8)
            
        }.navigationBarTitle("Channel Details", displayMode: .inline)
    }
}

struct ChannelDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelDetailsView(detail: ChannelDetail())
    }
}
