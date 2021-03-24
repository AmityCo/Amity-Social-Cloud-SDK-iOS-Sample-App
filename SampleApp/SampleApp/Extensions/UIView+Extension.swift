//
//  UIView+Extension.swift
//  SampleApp
//
//  Created by Nishan Niraula on 4/27/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

extension UIView {
    
    static var identifier: String {
        return String(describing: self)
    }
}

extension View where Self == ActivityIndicator {
    func configure(_ configuration: @escaping (Self.UIView) -> Void) -> Self {
        Self.init(isAnimating: self.isAnimating, configuration: configuration)
    }
}

extension UIViewController {
    
    static var identifier: String {
        return String(describing: self)
    }
}
