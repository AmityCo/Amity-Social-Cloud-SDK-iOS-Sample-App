//
//  CommunityEditorView.swift
//  SampleApp
//
//  Created by Michael Abadi on 13/07/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct CommunityEditorView<Model>: View where Model: EditorViewModel {
    
    @ObservedObject var viewModel: Model
    @Environment(\.presentationMode) var presentationMode
    
    init(viewModel: Model) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Form {
                Section(header: Text("DETAILS")) {
                    TextField("Display name", text: $viewModel.datasource.draft.displayName)
                    TextField("Description", text: $viewModel.datasource.draft.description)
                    Toggle(isOn: $viewModel.datasource.draft.isPrivate) {
                        Text("Private Community")
                    }
                }

                Section(header: Text("TAGS")) {
                    ForEach(viewModel.datasource.draft.tags.indices, id: \.self) { index in
                        TextField("Tag", text: self.$viewModel.datasource.draft.tags[index])
                    }
                    Button(action: {
                        print("[SampleApp] Add More Tags]")
                        self.viewModel.datasource.draft.tags.append("")
                    }) {
                        Text("Add More Tags")
                    }
                }
                
                Section(header: Text("Category Id")) {
                    TextField("Category Id", text: $viewModel.datasource.draft.categoryId)
                }

                Section(header: Text("METADATA")) {
                    TextField("Key", text: $viewModel.datasource.draft.key)
                    TextField("Value", text: $viewModel.datasource.draft.value)
                }

                if !viewModel.datasource.isEditMode {
                    Section(header: Text("USER ID")) {
                        if !viewModel.datasource.draft.userIds.contains(AmityManager.shared.client?.currentUserId ?? "Test User Id") {
                            Text("\(AmityManager.shared.client?.currentUserId ?? "Test User Id")")
                        }
                        ForEach(viewModel.datasource.draft.userIds.indices, id: \.self) { index in
                            TextField("User Id", text: self.$viewModel.datasource.draft.userIds[index])
                        }
                        Button(action: {
                            print("[SampleApp] Add More User]")
                            self.viewModel.datasource.draft.userIds.append("")
                        }) {
                            Text("Add More User")
                        }
                    }
                } else {
                    Section(header: Text("Member Count")) {
                        Text("\(viewModel.datasource.draft.membersCount) members")
                    }
                }
                                

                Section {
                    Button(action: {
                        if self.viewModel.datasource.isEditMode {
                            self.viewModel.action.updateCommunity { success, error in
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        } else {
                            self.viewModel.action.createCommunity { (success, error) in
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }) {
                        Text(self.viewModel.datasource.isEditMode ? "Update" : "Create")
                    }

                    if self.viewModel.datasource.isEditMode {
                        Button(action: {
                            self.viewModel.action.deleteCommunity { (success, error) in
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Text("Delete")
                        }
                    }
                }
            }
            .navigationBarTitle("Community Editor")
            .onAppear(perform: {
                UITableView.appearance().separatorStyle = .singleLine
            })
            .onDisappear(perform: {
                UITableView.appearance().separatorStyle = .none
            })
            
            if viewModel.datasource.isEditorLoading {
                ActivityIndicator(isAnimating: viewModel.datasource.isEditorLoading)
                .configure {
                    $0.color = .systemOrange
                    $0.style = .large
                }
                .frame(width: 100, height: 100)
                .background(Color("NeonAzure"))
                .cornerRadius(12)
                .shadow(radius: 12)
            }
        }
    }
}

struct ActivityIndicator: UIViewRepresentable {
    
    typealias UIView = UIActivityIndicatorView
    var isAnimating: Bool
    var configuration = {
        (indicator: UIView) in
    }

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView { UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        configuration(uiView)
    }
}

struct CommunityEditorView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityEditorView(viewModel: CommunityEditorViewModel())
    }
}
