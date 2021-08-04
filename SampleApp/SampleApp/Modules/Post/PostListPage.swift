//
//  PostListPage.swift
//  SampleApp
//
//  Created by Nutchaphon Rewik on 21/7/2564 BE.
//  Copyright © 2564 BE David Zhang. All rights reserved.
//

import SwiftUI
import AmitySDK

@available(iOS 14.0, *)
struct PostListPage: View {
    
    let options: AmityPostQueryOptions
    
    @State private var posts: [AmityPost] = []
    @State private var hasNext = false
    @State private var errorMessage: String?
    @State private var collection: AmityCollection<AmityPost>?
    @State private var token: AmityNotificationToken?
    
    var body: some View {
        Group {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .padding()
            } else {
                postsList()
            }
        }
        .navigationTitle("Posts")
        .onAppear {
            queryPosts()
        }
        .onDisappear {
            token = nil
        }
    }
    
    private func postsList() -> some View {
        ScrollView {
            ForEach(posts, id: \.postId) { post in
                VStack(alignment: .leading) {
                    Text("postId: \(post.postId)")
                        .font(.caption)
                    Text("dataType: \(post.dataType)")
                        .font(.caption)
                    Text("isDeleted: \(post.isDeleted ? "true": "false")")
                        .font(.caption)
                    Text("parentId: \(post.parentPostId ?? "null")")
                        .font(.caption)
                    Text("created: \(DateFormatter.localizedString(from: post.createdAt, dateStyle: .short, timeStyle: .short))")
                        .font(.caption)
                }
                .padding(.leading)
                .padding(.trailing)
                .padding(.top)
                Divider()
            }
            if hasNext {
                VStack(alignment: .center) {
                    Button("Load Next Page") {
                        collection?.nextPage()
                    }
                }
                Divider()
            }
        }
    }
    
    private func queryPosts() {
        guard let postRepository = AmityManager.shared.postRepository else {
            assertionFailure("postRepository must be ready at this point.")
            return
        }
        collection = postRepository.getPosts(options)
        token = collection?.observe { _collection, changes, error in
            var newPosts: [AmityPost] = []
            for index in (0..<_collection.count()) {
                if let post = _collection.object(at: index) {
                    newPosts.append(post)
                }
            }
            errorMessage = error?.localizedDescription
            hasNext = _collection.hasNext
            posts = newPosts
        }
    }
    
}

