//
//  StringExtension.swift
//  SampleApp
//
//  Created by Michael Abadi Santoso on 2/28/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation

extension String {

    static func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

