//
//  TestController.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/15/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation
import UIKit

// NOTE:
// Ignore stuffs in this class. This class is just for quick testing of sdk stuffs inside sample app.
class TestController: UIViewController {
    
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button1 = UIBarButtonItem(title: "A1", style: .plain, target: self, action: #selector(onButton1Tap))
        let button2 = UIBarButtonItem(title: "A2", style: .plain, target: self, action: #selector(onButton2Tap))
        let button3 = UIBarButtonItem(title: "A3", style: .plain, target: self, action: #selector(onButton3Tap))
        let button4 = UIBarButtonItem(title: "A4", style: .plain, target: self, action: #selector(onButton4Tap))
        
        self.navigationItem.rightBarButtonItems = [button1, button2, button3, button4]
        
        
        view.addSubview(imageView)
        imageView.backgroundColor = .red
    }
        
    @objc func onButton1Tap() {
        let client = AmityManager.shared.client!
    }
        
    @objc func onButton2Tap() {
        let fileURL = "file:///Users/nishanniraula/Library/Developer/CoreSimulator/Devices/1B6C6E87-6341-4CBA-AE86-24AD4D304CE3/data/Containers/Data/Application/249A9D19-10B3-49A7-BE07-70FCD131D540/tmp/9AEC86D7-0062-4882-9076-15BF5150E5F7.png"
        
        if let image = UIImage(contentsOfFile: fileURL) {
            imageView.image = image
            Log.add(info: "Image loaded")
        } else {
            Log.add(info: "Cannot load image")
        }
        

    }
    
    @objc func onButton3Tap() {

        let fileURL = "file:///Users/nishanniraula/Library/Developer/CoreSimulator/Devices/1B6C6E87-6341-4CBA-AE86-24AD4D304CE3/data/Containers/Data/Application/249A9D19-10B3-49A7-BE07-70FCD131D540/tmp/9AEC86D7-0062-4882-9076-15BF5150E5F7.png"
        
        // /Users/nishanniraula/Library/Developer/CoreSimulator/Devices/1B6C6E87-6341-4CBA-AE86-24AD4D304CE3/data/Containers/Data/Application/506AB29F-16FA-4DF2-98B0-B887B6B75D1A/tmp/3C08B925-AA6B-420A-974D-1995967DE05E.png
        
        let url = URL(string: fileURL)!
        
        Log.add(info: "Path: \(url.path)")
        if let image = UIImage(contentsOfFile: url.path) {
            imageView.image = image
            Log.add(info: "Image loaded")
        } else {
            Log.add(info: "Cannot load image")
        }
    }
    
    @objc func onButton4Tap() {

    }
    
    func getUserInput(completion: @escaping (String, String) -> Void) {
        let alert = UIAlertController(title: "Assign Role", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addTextField { (textField) in
            textField.placeholder = "User Id"
            textField.autocapitalizationType = .none
        }
        alert.addTextField { (textField) in
            textField.autocapitalizationType = .none
            textField.placeholder = "Input"
        }
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (action) in
            guard let id = alert.textFields?[0].text, let role = alert.textFields?[1].text, !id.isEmpty, !role.isEmpty else { return }
            completion(id, role)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

extension AmityDataStatus {
    var description: String {
        switch self {
        case .local:
            return "Local"
        case .error:
            return "Error"
        case .fresh:
            return "Fresh"
        case .notExist:
            return "Not Exists"
        default:
            return "Unknown"
        }
    }
}

extension AmitySyncState {
    var description: String {
        switch self {
        case .default:
            return "Default"
        case .error:
            return "Error"
        case .synced:
            return "Synced"
        case .syncing:
            return "Syncing"
        default:
            return "Unknown"
        }
    }
}

extension AmityMediaSize {
    var description: String {
        switch self {
        case .full:
            return "Full"
        case .large:
            return "Large"
        case .medium:
            return "Medium"
        case .small:
            return "Small"
        default:
            return "Not Available"
        }
    }
}
