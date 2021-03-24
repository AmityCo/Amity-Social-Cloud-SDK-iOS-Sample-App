//
//  SwiftUIImagePicker.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/6/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import SwiftUI

struct SwiftUIImagePicker: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = UIImagePickerController
    
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Left empty
    }
    
    func makeCoordinator() -> ImagePickerCoordinator {
        return ImagePickerCoordinator(picker: self)
    }

    // MARK:- Coordinator
    
    class ImagePickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        var imagePicker: SwiftUIImagePicker
        
        init(picker: SwiftUIImagePicker) {
            self.imagePicker = picker
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let selectedImage = info[.originalImage] as? UIImage {
                self.imagePicker.image = selectedImage
            }
            
            self.imagePicker.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        Text("Image Picker")
    }
}
