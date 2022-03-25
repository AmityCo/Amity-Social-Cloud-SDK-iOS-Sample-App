//
//  Debouncer.swift
//  SampleApp
//
//  Created by Nishan Niraula on 11/23/21.
//  Copyright © 2021 David Zhang. All rights reserved.
//

import Foundation

// Simple debouncer for search
@objc public class Debouncer: NSObject {
    
    @objc public var delay: Double
    
    private var callback: (() -> Void)?
    
    private weak var timer: Timer?
    
    @objc public init(delay: TimeInterval) {
        self.delay = delay
    }
    
    deinit {
        timer?.invalidate()
    }
    
    @objc public func setCallback(_ callback: (() -> Void)?) {
        self.callback = callback
    }
    
    @objc public func call() {
        timer?.invalidate()
        let nextTimer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(fire), userInfo: nil, repeats: false)
        timer = nextTimer
    }
    
    @objc public func fire() {
        self.callback?()
    }
    
}
