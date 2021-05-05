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
    
    var regions = ["Global","EU", "SG","US"]
    var regionEndpointDict: [String: String] = ["Global": AmityRegionalEndpoint.GLOBAL, "EU": AmityRegionalEndpoint.EU, "SG": AmityRegionalEndpoint.SG, "US": AmityRegionalEndpoint.US]
    @State var selectedRegion: Int = -1
    
    @State var keys: [String] = []
    
    @Binding var isSetupComplete: Bool
    @State var selectedEnvironment: Int = UserDefaults.standard.isStagingEnvironment ? 0 : 1
    @State var selectedApiKey: Int = 1
    @State var enteredApiKey: String = ""
    @State var customHttpEndpoint: String = ""
    @State var customSocketEndpoint: String = ""
    
    
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
                }
                
                if self.selectedEnvironment == 1 {
                    Section(header: Text("Custom Endpoints"), footer: Text("Select region or enter http/socket endpoint manually. Example: http://api.amity.co")) {
                        
                        Picker(selection: $selectedRegion, label: Text("Region:")) {
                            ForEach(0..<regions.count, id: \.self) { index in
                                Text(self.regions[index])
                            }
                        }
                        .onReceive([self.selectedRegion].publisher.first()) { index in
                            guard index != -1 else { return }
                            
                            let key = regions[index]
                            
                            self.customHttpEndpoint = regionEndpointDict[key] ?? ""
                            self.customSocketEndpoint = regionEndpointDict[key] ?? ""
                        }
                        
                        TextField("Enter http endpoint", text: $customHttpEndpoint)
                            .font(.subheadline)
                            .autocapitalization(.none)
                        TextField("Enter socket endpoint", text: $customSocketEndpoint)
                            .font(.subheadline)
                            .autocapitalization(.none)
                    }
                }
                
                Button(action: {
                    let apiKeySelection = self.keys[self.selectedApiKey]
                    
                    UserDefaults.standard.currentApiKey = apiKeySelection
                    UserDefaults.standard.isStagingEnvironment = self.selectedEnvironment == 0 ? true : false
                    
                    UserDefaults.standard.customHttpEndpoint = self.customHttpEndpoint
                    UserDefaults.standard.customSocketEndpoint = self.customSocketEndpoint
                    
                    UserDefaults.standard.synchronize()
                    
                    self.isSetupComplete = !apiKeySelection.isEmpty
                }) {
                    Text("Proceed")
                }
                
                Button(action: {
                    
                    self.selectedRegion = -1
                    self.customHttpEndpoint = ""
                    self.customSocketEndpoint = ""
                    self.selectedEnvironment = 0
                    
                }) {
                    Text("Reset")
                }
            }
            .navigationBarTitle("SDK Setup", displayMode: .inline)
            .onAppear {
                var availableApiKeys = UserDefaults.standard.apiKeys
                
                if let currentApiKey = UserDefaults.standard.currentApiKey,
                   let index = availableApiKeys.firstIndex(of: currentApiKey) {
                    selectedApiKey = index
                }
                
                if availableApiKeys.isEmpty {
                    // Fetch one from info.plist if available
                    guard let apiKeyObject = Bundle.main.object(forInfoDictionaryKey: "AmityAPIKey"), let key = apiKeyObject as? String else { return }
                    
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


