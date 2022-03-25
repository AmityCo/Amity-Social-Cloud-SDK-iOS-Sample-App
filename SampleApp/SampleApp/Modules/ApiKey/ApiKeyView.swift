//
//  ApiKeyView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/8/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

/*
 This class is for sample app purpose only. This is not a production ready code.
 Please don't use it in production environment.
 */
struct ApiKeyView: View {
    
    enum EnvironmentType: Int, CaseIterable {
        case production = 0
        case staging
        case custom
        
        var identifier: String {
            switch self {
            case .production:
                return "Production"
            case .staging:
                return "Staging"
            case .custom:
                return "Custom"
            }
        }
    }

    @State var environmentTitles: [String] = []
    @State var userCustomEnvironments = [ApiEnvironment]()
    @State var selectedEnvironmentIndex: Int = 0 // 0 is production
    
    var regions: [String] = [AmityRegion.global.regionIdentifier, AmityRegion.EU.regionIdentifier, AmityRegion.SG.regionIdentifier, AmityRegion.US.regionIdentifier]
    @State var selectedRegionIndex: Int = 0
    
    @State var enteredApiKey: String = ""
    @State var enteredUserId: String = ""
    
    @Binding var isSetupComplete: Bool
    @State var isInitialDataSetupDone = false
    
    var selectedEnvironment: EnvironmentType {
        switch selectedEnvironmentIndex {
        case 0:
            return .production
        case 1:
            return .staging
        default:
            return .custom
        }
    }
    
    var customEnvironmentOffset: Int {
        // Custom environment starts from index 2. 0 -> production, 1 -> staging
        return 2
    }
    
    var defaultEnvironments: [String] {
        return [EnvironmentType.production.identifier, EnvironmentType.staging.identifier]
    }
    
    var body: some View {
        NavigationView {
            Form {
                
                // Environment Setup & Selection
                Section(header: Text("Setup Environment")) {
                    NavigationLink(destination: ApiEnvironmentView(onCreate: { environment in
                        environmentTitles.append(environment.name)
                        userCustomEnvironments.append(environment)
                    })) {
                        Text("Add New Environment")
                            .font(.subheadline)
                    }
                    
                    Picker(selection: $selectedEnvironmentIndex, label: Text("Selected Environment"), content: {
                        
                        ForEach(0..<environmentTitles.count, id: \.self) { index in
                            Text(self.environmentTitles[index])
                                .lineLimit(2)
                                .font(.caption)
                        }
                    })
                }
                
                // Region setup for production environment
                if selectedEnvironment != .custom {
                    Section(header: Text("Api Key & Region")) {
                        
                        TextField("Api Key", text: $enteredApiKey)
                        
                        if selectedEnvironment == .production {
                            Picker(selection: $selectedRegionIndex, label: Text("Region:")) {
                                ForEach(0..<regions.count, id: \.self) { index in
                                    Text(self.regions[index])
                                        .lineLimit(2)
                                        .font(.caption)
                                }
                            }
                            .onReceive([self.selectedRegionIndex].publisher.first()) { index in
                                guard index != -1 else { return }
                                // Do something
                            }
                        }
                    }
                }
                
                Section(header: Text("Enter User Id")) {
                    TextField("User Id:", text: $enteredUserId)
                        .font(.subheadline)
                        .autocapitalization(.none)
                }
                
                if selectedEnvironment == .custom {
                    let environment = userCustomEnvironments[selectedEnvironmentIndex - customEnvironmentOffset]

                    Section(header: Text("Current Selection:")) {
                        Group {
                            Text("Http URL: \(environment.httpUrl)")
                            Text("Rpc URL: \(environment.rpcUrl)")
                            Text("Mqtt Host: \(environment.mqttHost)")
                            Text("Api Key: \(environment.apiKey)")
                        }
                        .font(.subheadline)
                    }
                }
                
                FormButton(title: "Proceed") {
                    guard !enteredUserId.isEmpty else { return }
                    
                    // Amity Client Setup
                    // !!! IMPORTANT !!!
                    //
                    // SDK needs to be setup before any method can be used. This is a two step process.
                    //
                    // Step 1: Create an instance of AmityClient with provided apikey.
                    // This step is handled in AmityManager class.
                    
                    // Step 2: Register userId using `registerDevice(_:)` method.
                    // This step is handled in HomeViewController class.
                    
                    var apiKey: String = ""
                    
                    // If production is selected, use region & setup AmityClient
                    switch selectedEnvironment {
                    case .custom:
                        let environment = userCustomEnvironments[selectedEnvironmentIndex - customEnvironmentOffset]
                        
                        apiKey = environment.apiKey
                        AmityManager.shared.setup(environment: environment)
                        
                    case .production:
                        guard !enteredApiKey.isEmpty else { return }
                        
                        apiKey = enteredApiKey
                        AmityManager.shared.setup(apiKey: enteredApiKey, region: AmityRegion(rawValue: selectedRegionIndex) ?? .global)
                        
                    case .staging:
                        guard !enteredApiKey.isEmpty else { return }
                        
                        apiKey = enteredApiKey
                        let environment = ApiEnvironment(name: "Staging", apiKey: apiKey, httpUrl: "https://api.staging.amity.co", rpcUrl: "https://api.staging.amity.co", mqttHost: "ssq.staging.amity.co")
                        AmityManager.shared.setup(environment: environment)
                    }
                    
                    UserDefaults.standard.userId = self.enteredUserId
                    UserDefaults.standard.currentApiKey = apiKey
                    UserDefaults.standard.synchronize()
                    
                    self.isSetupComplete = true
                }
                
                FormButton(title: "Reset All") {
                    self.selectedRegionIndex = 0
                    self.selectedEnvironmentIndex = 0
                    self.enteredApiKey = ""
                }
            }
            .navigationBarTitle("SDK Setup", displayMode: .inline)
            .onAppear {
                guard !isInitialDataSetupDone else { return }
                
                // Environments Setup
                self.userCustomEnvironments = UserDefaults.standard.getSavedEnvironments()
                let environmentTitles = userCustomEnvironments.map{ $0.name }
                
                var availableEnvironments = defaultEnvironments
                availableEnvironments.append(contentsOf: environmentTitles)
                self.environmentTitles = availableEnvironments
                
                // User Id Setup
                self.enteredUserId = UserDefaults.standard.userId ?? "victimIOS"
                
                // Api Key Setup
                self.enteredApiKey = UserDefaults.standard.currentApiKey ?? ""
                
                // Prevent re intialization
                self.isInitialDataSetupDone = true
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


struct ApiEnvironment: Codable {
    var name: String = ""
    var apiKey: String = ""
    var httpUrl: String = ""
    var rpcUrl: String = ""
    var mqttHost: String = ""
    
    func isValid() -> Bool {
        guard !name.isEmpty && !apiKey.isEmpty && !httpUrl.isEmpty && !rpcUrl.isEmpty else { return false }
        return true
    }
    
    static func encodeData(data: ApiEnvironment) -> Data? {
        let encodedData = try? JSONEncoder().encode(data)
        return encodedData
    }
    
    static func decodeData(data: Data) -> ApiEnvironment? {
        let decodedData = try? JSONDecoder().decode(ApiEnvironment.self, from: data)
        return decodedData
    }
    
    var description: String {
        return "Name: \(name) ApiKey: \(apiKey), Http: \(httpUrl), Rpc: \(rpcUrl), Mqtt: \(mqttHost)"
    }
}

struct ApiEnvironmentView: View {
    
    @State var environment: ApiEnvironment = ApiEnvironment()
    @State var buttonText = "Create"
    
    @Environment(\.presentationMode) var presentation
    
    var onCreate: (ApiEnvironment) -> Void
    
    var hint = """
    Format:
    
    Http Url: https://api.amity.co
    Socket Url: https://api.amity.co
    Mqtt Host: ssq.amity.co (without scheme mqtts://)
    
    All fields are mandatory!
    """
    
    var body: some View {
        Form {
            Section(header: Text("Add New Environment"), footer: Text(hint).font(.footnote)) {
                TextField("Environment Name:", text: $environment.name)
                TextField("Api Key:", text: $environment.apiKey)
                    .autocapitalization(.none)
                TextField("Http Url:", text: $environment.httpUrl)
                    .autocapitalization(.none)
                TextField("Socket Url", text: $environment.rpcUrl)
                    .autocapitalization(.none)
                TextField("Mqtt Host", text: $environment.mqttHost)
                    .autocapitalization(.none)
            }
            .font(.subheadline)
            
            Section {
                HStack {
                    Spacer()
                    Button {
                        guard environment.isValid() else { return }
                        
                        UserDefaults.standard.saveEnvironment(environment: environment)
                        UserDefaults.standard.synchronize()
                        
                        onCreate(environment)
                        
                        // Pop screen
                        presentation.wrappedValue.dismiss()
                        
                    } label: {
                        Text(buttonText)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            if !environment.name.isEmpty {
                buttonText = "Update"
            } else {
                buttonText = "Create"
            }
        }
    }
}

struct FormButton: View {
    
    let title: String
    let action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack {
                Spacer()
                Text(title)
                Spacer()
            }
        }
    }
}
