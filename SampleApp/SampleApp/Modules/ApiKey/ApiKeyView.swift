//
//  ApiKeyView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/8/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct ApiKeyView: View {
    
    var environments: [String] = ["Staging", "Custom"]
    @State var keys: [String] = []
    
    @Binding var isSetupComplete: Bool
    @State var selectedEnvironment: Int = UserDefaults.standard.isStagingEnvironment ? 0 : 1
    @State var selectedApiKey: Int = 1
    @State var enteredApiKey: String = ""
    @State var apiDomainKey: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Api Key")) {
                    TextField("Enter New Key", text: $enteredApiKey)
                        .font(.subheadline)
                    Button(action: {
                        guard !self.enteredApiKey.isEmpty else { return }
                        
                        self.keys.append(self.enteredApiKey)
                        self.saveApiKeys(keys: self.keys)
                        self.enteredApiKey = ""
                    }) {
                        Text("Save Api Key")
                    }
                }
                
                Section(header: Text("Current Selection"), footer: Text("This api key & environment will be used in sdk")) {
                    Picker(selection: $selectedApiKey, label: Text("Api Key:")) {
                        ForEach(0..<self.keys.count, id: \.self) { index in
                            Text(self.keys[index])
                                .lineLimit(1)
                                .font(.caption)
                        }
                    }
                    
                    Picker(selection: $selectedEnvironment, label: Text("Env:")) {
                        ForEach(0..<environments.count, id: \.self) { index in
                            Text(self.environments[index])
                                .lineLimit(1)
                                .font(.caption)
                        }
                    }
                    
                    TextField("Enter Custom Domain Key", text: $apiDomainKey)
                        .font(.subheadline)
                }
                
                Button(action: {
                    let apiKeySelection = self.keys[self.selectedApiKey]
                    
                    UserDefaults.standard.currentApiKey = apiKeySelection
                    UserDefaults.standard.isStagingEnvironment = self.selectedEnvironment == 0 ? true : false
                    UserDefaults.standard.apiDomainKey = self.apiDomainKey
                    UserDefaults.standard.synchronize()
                    
                    self.isSetupComplete = !apiKeySelection.isEmpty
                }) {
                    Text("Proceed")
                }
                
            }
            .navigationBarTitle("SDK Setup", displayMode: .inline)
            .onAppear {
                var availableApiKeys = UserDefaults.standard.apiKeys
                
                if availableApiKeys.isEmpty {
                    // Fetch one from info.plist if available
                    guard let apiKeyObject = Bundle.main.object(forInfoDictionaryKey: "EKOChatAPIKey"), let key = apiKeyObject as? String else { return }
                    
                    availableApiKeys.append(key)
                }
                
                self.saveApiKeys(keys: availableApiKeys)
                self.keys = availableApiKeys
            }
        }
    }
    
    func saveApiKeys(keys: [String]) {
        UserDefaults.standard.apiKeys = keys
        UserDefaults.standard.synchronize()
    }
}

struct ApiKeyView_Previews: PreviewProvider {
    
    static var previews: some View {
        Text("ApiKey View")
    }
}

struct MainContainerView: View {
    
    @State var isSetupComplete = false
    
    var body: some View {
        if self.isSetupComplete {
            if #available(iOS 14.0, *) {
                return AnyView(SwiftUIMainTabView().ignoresSafeArea(.keyboard, edges: .bottom))
            } else {
                return AnyView(SwiftUIMainTabView())
            }
        } else {
            return AnyView(ApiKeyView(isSetupComplete: $isSetupComplete))
        }
    }
    
}


