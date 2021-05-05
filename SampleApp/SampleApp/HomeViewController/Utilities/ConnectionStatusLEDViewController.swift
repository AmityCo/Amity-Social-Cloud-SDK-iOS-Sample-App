//
//  ConnectionStatusLEDViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/8/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import AmitySDK

/// Responsible to update the LED status, according to the given `AmityClient` `connectionStatus`
final class ConnectionStatusLEDViewController: UIViewController {
    @IBOutlet private weak var connectionStatusUIImageView: UIImageView!
    private var observation: NSKeyValueObservation?

    /// To be injected.
    var client: AmityClient!

    override func viewDidLoad() {
        super.viewDidLoad()
        observation = client.observe(\.connectionStatus) { [weak self] client, _ in
            self?.updateColor(with: client.connectionStatus)
        }
    }

    private func updateColor(with connectionStatus: AmityConnectionStatus) {
        connectionStatusUIImageView.tintColor = color(for: connectionStatus)
    }

    private func color(for connectionStatus: AmityConnectionStatus) -> UIColor? {
        let colorName = self.colorName(for: connectionStatus)
        return UIColor(named: colorName)
    }

    private func colorName(for connectionStatus: AmityConnectionStatus) -> String {
        switch connectionStatus {
        case .connected:
            return "AmityGreen"
        case .connecting:
            return "AmityOrange"
        case .notConnected,
             .disconnected:
            fallthrough
        @unknown default:
            return "AmityRed"
        }
    }
}
