//
//  Log.swift
//  SampleApp
//
//  Created by Nishan Niraula on 6/26/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation

class Log {
    
    static var isEnabled = true
    
    // Prints on console on this format:
    // › [SampleApp]: [ViewController.methodName()] : My Log
    static func add(info:Any, fileName:String = #file, methodName:String = #function) {
        if isEnabled {
            print("› [SampleApp]: [\(fileName.components(separatedBy: "/").last!.components(separatedBy: ".").first!).\(methodName)] : \(info)")
        }
    }
}

