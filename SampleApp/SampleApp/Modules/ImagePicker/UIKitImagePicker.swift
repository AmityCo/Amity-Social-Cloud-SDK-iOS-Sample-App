//
//  UIKitImagePicker.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/6/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation
import UIKit

// Code to pick images in sample app
class UIKitImagePicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    fileprivate weak var viewController: UIViewController?
    fileprivate var completionHandler: ((UIImage?)->())?
    
    var infoHandler: (([UIImagePickerController.InfoKey: Any]) -> Void)?
    
    public func displayImagePicker(in vc: UIViewController, anchorView: UIView, onSelection: @escaping (UIImage?)->()) {
        
        self.completionHandler = onSelection
        self.viewController = vc
        
        let alert = UIAlertController(title: "Add Photo", message: "Take photo from your camera or select from your photo library.", preferredStyle: .actionSheet)
        let action1 = UIAlertAction(title: "Take Photo", style: .default) { (_) in
            self.initImagePicker(sourceType: .camera)
        }
        
        let action2 = UIAlertAction(title: "Choose From Library", style: .default) { (_) in
            self.initImagePicker(sourceType: .photoLibrary)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(action1)
        alert.addAction(action2)
        alert.addAction(cancel)
        
        alert.popoverPresentationController?.sourceView = anchorView
        alert.popoverPresentationController?.sourceRect = anchorView.bounds
        
        viewController?.present(alert, animated: true, completion: nil)
    }
    
    private func initImagePicker(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = false
        self.viewController?.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        let selectedImage = info[.originalImage] as? UIImage
        
        completionHandler?(selectedImage)
        infoHandler?(info)
        
        picker.dismiss(animated: true, completion: nil)
    }
}

