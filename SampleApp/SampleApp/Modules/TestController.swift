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
    }
        
    @objc func onButton1Tap() {
        
    }
    
    @objc func onButton2Tap() {
        
    }
    
    @objc func onButton3Tap() {

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

extension EkoDataStatus {
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

extension EkoSyncState {
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
