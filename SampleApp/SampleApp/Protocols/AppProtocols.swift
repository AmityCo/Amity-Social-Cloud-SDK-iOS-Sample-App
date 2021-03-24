//
//  AppProtocols.swift
//  SampleApp
//
//  Created by Nishan Niraula on 6/12/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import Foundation

// To notify when data source changes
protocol DataSourceListener: AnyObject {
    func didUpdateDataSource()
}
