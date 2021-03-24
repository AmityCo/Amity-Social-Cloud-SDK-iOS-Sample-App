//
//  ListViewController.swift
//  SampleApp
//
//  Created by Nishan Niraula on 10/5/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit

struct ListItem {
    let id: String
    let title: String
}

class ListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView()
    
    var listTitle: String = ""
    var listItemTapAction: ((ListItem, Int)->())?
    var items = [ListItem]()
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        
        self.title = listTitle
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.frame
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier)!
        cell.textLabel?.text = items[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        listItemTapAction?(item, indexPath.row)
    }
}
