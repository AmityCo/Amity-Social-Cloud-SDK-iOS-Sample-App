//
//  NotificationLogViewController.swift
//  SampleApp
//
//  Created by Nutchaphon Rewik on 7/2/2565 BE.
//  Copyright © 2565 BE David Zhang. All rights reserved.
//

import UIKit

class NotificationLogViewController: UIViewController {

    private var payloads: [String] = []
    
    @IBOutlet private weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Push Notification Log"
        payloads = AmityManager.shared.pushPayloads.reversed()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
}

extension NotificationLogViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        payloads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let jsonString = payloads[indexPath.row]
        let oneLine = jsonString.components(separatedBy: .whitespacesAndNewlines).joined(separator: " ")
        cell.textLabel?.text = oneLine
        return cell
    }
    
}

extension NotificationLogViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        UIPasteboard.general.string = payloads[indexPath.row]
        let alertController = UIAlertController(title: "Payload Copied", message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(ok)
        present(alertController, animated: true, completion: nil)
    }
    
}
