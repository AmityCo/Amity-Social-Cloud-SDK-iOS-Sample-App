//
//  ConnectionStatusLEDViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/8/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import EkoChat

/// Responsible to update the LED status, according to the given `EkoClient` `connectionStatus`
final class ConnectionStatusLEDViewController: UIViewController {
    @IBOutlet private weak var connectionStatusUIImageView: UIImageView!
    private var observation: NSKeyValueObservation?

    /// To be injected.
    var client: EkoClient!

    override func viewDidLoad() {
        super.viewDidLoad()
        observation = client.observe(\.connectionStatus) { [weak self] client, _ in
            self?.updateColor(with: client.connectionStatus)
        }
    }

    private func updateColor(with connectionStatus: EkoConnectionStatus) {
        connectionStatusUIImageView.tintColor = color(for: connectionStatus)
    }

    private func color(for connectionStatus: EkoConnectionStatus) -> UIColor? {
        let colorName = self.colorName(for: connectionStatus)
        return UIColor(named: colorName)
    }

    private func colorName(for connectionStatus: EkoConnectionStatus) -> String {
        switch connectionStatus {
        case .connected:
            return "EkoGreen"
        case .connecting:
            return "EkoOrange"
        case .notConnected,
             .disconnected:
            fallthrough
        @unknown default:
            return "EkoRed"
        }
    }
}
