//
//  AboutViewController.swift
//  SampleApp
//
//  Created by Federico Zanetello on 6/12/18.
//  Copyright © 2018 David Zhang. All rights reserved.
//

import UIKit

final class AboutTableViewController: UITableViewController {

    // MARK: UITableViewDataSource

    private enum Section: Int {
        case apiKey = 0
        case sdkVersion
        case appVersion
        case userMetaInfo
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        guard let section = Section(rawValue: indexPath.section) else {
            assertionFailure("Unknown section '\(indexPath.section)', update AboutTableViewController.Section")
            return cell
        }

        cell.textLabel?.text = text(for: section)
        return cell
    }

    private func text(for section: Section) -> String? {
        switch section {
        case .apiKey: return apiKey()
        case .sdkVersion: return SDKVersion()
        case .appVersion: return appVersionBuild()
        case .userMetaInfo: return userMetaInformation()
        }
    }

    /// Returns the current SDK API key.
    ///
    /// Change this value in the Info.plist
    private func apiKey() -> String? {
        return UserDefaults.standard.currentApiKey
    }

    /// Returns this app build and version number.
    private func appVersionBuild() -> String? {
        let mainBundle = Bundle.main
        guard
            let appVersion = mainBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let versionBuild = mainBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            else { return nil }
        return String(format: "v%1@ b%2@", appVersion, versionBuild)
    }

    /// Returns the SDK version embedded in this app.
    ///
    /// Get the latest version at https://docs.ekomedia.technology
    private func SDKVersion() -> String? {
        guard
            let infoDictionary: [String: Any] = Bundle(for: EkoUser.self).infoDictionary,
            let name = infoDictionary["CFBundleName"] as? String,
            let version = infoDictionary["CFBundleShortVersionString"] as? String
            else { return nil }
        return String(format: "%1@ v%2@", name, version)
    }
        
    /// Returns the current user meta information.
    private func userMetaInformation() -> String? {
        return EkoManager.shared.client?.currentUser?.object?.metadata?.description
    }
}
