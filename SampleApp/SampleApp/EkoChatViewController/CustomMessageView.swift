//
//  CustomMessageView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 5/6/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import SwiftUI

struct CustomMessageView: View {
    
    @State var key: String = ""
    @State var textValue: String = ""
    @State var arrayValue: String = ""
    
    @State var customObjectKey: String = ""
    @State var customObjectValue: String = ""
    
    @ObservedObject var viewModel = CustomMessageViewModel()
    
    var sendButtonAction: (([String: Any]) -> Void)?

    
    let note: String = """
    Note:

    Custom message accepts a json object as an input from user. So use this form to create the json object.

    1. Add key value pair. A single key can have a single type of value. Value types can be one of the text, array of strings or custom object.

    2. You can add as many key value pair as you like. Fill up the input & tap on create

    3. Your custom json structure will be shown at the bottom of the screen.

    4. Tap on send button to create a message.
    """
    
    
    var body: some View {
        Form {
            
            Section(header: Text("Enter Key")) {
                TextField("Key", text: $key)
            }
            
            Section(header: Text("Enter Value"), footer: Text("For array use comma (,) separated string")) {
                                
                TextField("Single Value", text: $textValue)
                TextField("Array", text: $arrayValue)
                Text("Or set custom object as value")
                    .font(.system(size: 14))
                
                TextField("Key", text: $customObjectKey)
                TextField("Value", text: $customObjectValue)
                
                Button(action: {
                    guard !key.isEmpty else { return }
                    
                    if !textValue.isEmpty {
                        viewModel.userInput[key] = textValue
                    } else if !arrayValue.isEmpty {
                        let arr = arrayValue.components(separatedBy: ",").map {  $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        viewModel.userInput[key] = arr
                    } else if !customObjectKey.isEmpty {
                        let newPair = [customObjectKey: customObjectValue]
                        viewModel.userInput[key] = newPair
                    }
                    
                    key = ""
                    textValue = ""
                    arrayValue = ""
                    customObjectKey = ""
                    customObjectValue = ""
                    
                }, label: {
                    HStack {
                        Spacer()
                        Text("Add")
                        Spacer()
                    }
                })
            }
            
            Text(note)
                .font(.system(size: 14))
                .foregroundColor(Color(UIColor.darkGray))
                .padding(.vertical)
            
            
            Section {
                Button(action: {
                    sendButtonAction?(viewModel.userInput)
                }, label: {
                    HStack {
                        Spacer()
                        Text("Send")
                        Spacer()
                    }
                })
            }
            
            Section {
                Text("Your Data: \n\(viewModel.getUserInputDescription())")
            }
            
        }
        
    }
}

struct CustomMessageView_Previews: PreviewProvider {
    static var previews: some View {
        CustomMessageView(key: "")
    }
}

class CustomMessageViewModel: ObservableObject {
    
    @Published var userInput = [String: Any]()
    
    func getUserInputDescription() -> String {
        
        let serializedData = try? JSONSerialization.data(withJSONObject: userInput, options: .prettyPrinted)
        
        if let data = serializedData, let prettyPrintedData = String(data: data, encoding: .utf8) {
            return prettyPrintedData
        } else {
            return userInput.debugDescription
        }
    }
}
