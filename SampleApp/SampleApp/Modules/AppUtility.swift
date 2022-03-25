//
//  AppUtility.swift
//  SampleApp
//
//  Created by Nishan Niraula on 11/24/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import Foundation
import UIKit

class AppUtility {
    
    static func showAlert(in vc: UIViewController, title: String, message: String, action: ((UIAlertAction) -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Dismiss", style: .default, handler: action)
        alertController.addAction(action)
        
        vc.present(alertController, animated: true, completion: nil)
    }
    
    static func showActionSheet(in vc: UIViewController, title: String, message: String, actions: [UIAlertAction]) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        for action in actions {
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        vc.present(alertController, animated: true, completion: nil)
    }
    
}
