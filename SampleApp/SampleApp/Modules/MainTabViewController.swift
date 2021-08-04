//
//  MainTabViewController.swift
//  SampleApp
//
//  Created by Nishan Niraula on 4/27/20.
//  Copyright © 2020 David Zhang. All rights reserved.
//

import UIKit
import SwiftUI

/*
 This class sets up various screens in sample app.
 */
class MainTabViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabControllers()
    }
    
    func setupTabControllers() {
        // Our sdk also supports push notification. We regisiter for push notification here
        let client = AmityManager.shared.client!
        if let token = UserDefaults.standard.deviceToken, (UserDefaults.standard.isRegisterdForPushNotification ?? true) {
            let pushNotificationManager =  PushNotificationRegistrationManager(client: client)
            pushNotificationManager.register(token: token) { (result) in
                switch result {
                case .success:
                    Log.add(info: "✅ Device is registered: \(token)")
                case .failure(let error):
                    Log.add(info: "🛑 Failed to register: \(error.localizedDescription)")
                }
            }
        }
        
        // Home Screen
        let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
        let homeController = homeStoryboard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        homeController.tabBarItem = UITabBarItem(title: "Chat", image: UIImage(named: "tab_chat"), tag: 0)
        homeController.channelType = .standard
        
        // Feed Screen
        let postsFeedStoryboard = UIStoryboard(name: "Feed", bundle: nil)
        
        // Post Selection Screen
        let postListController = ListViewController()
        postListController.listTitle = "Feed"
        postListController.items = [
            "Normal Feed",
            "Global Feed",
            "Create Comment",
            "Get Latest Comment",
            "Get Posts"
        ].map{ ListItem(id: $0, title: $0) }
        postListController.listItemTapAction = { item, index in
            switch index {
            case 0, 1:
                let postsFeedController = postsFeedStoryboard.instantiateViewController(withIdentifier: UserPostsFeedViewController.identifier) as! UserPostsFeedViewController
                postsFeedController.isGlobalFeed = index == 1
                
                let feedManager = UserPostsFeedManager(client: client, userId: nil)
                postsFeedController.feedManager = feedManager
                
                postListController.navigationController?.pushViewController(postsFeedController, animated: true)
            case 2:
                let controller = UIHostingController(rootView: CommentCreateTestView())
                postListController.navigationController?.pushViewController(controller, animated: true)
            case 3:
                let controller = UIHostingController(rootView: LatestCommentView())
                postListController.navigationController?.pushViewController(controller, animated: true)
            case 4:
                if #available(iOS 14.0, *) {
                    let postQuerySettingsPage = PostQuerySettingsPage()
                    let vc = UIHostingController(rootView: postQuerySettingsPage)
                    postListController.navigationController?.pushViewController(vc, animated: true)
                } else {
                    assertionFailure("Unhandled case")
                }
            default:
                assertionFailure("Unhandled case")
                break
            }
        }
        postListController.tabBarItem = UITabBarItem(title: "My Feed", image: UIImage(named: "tab_feed"), tag: 1)
        
        // User Selection Screen
        let userListOptionController = ListViewController()
        userListOptionController.listTitle = "Users"
        userListOptionController.items = ["User List","Individual User", "Check Permission", "My Following List", "My Follower List"].map{ ListItem(id: $0, title: $0)}
        userListOptionController.listItemTapAction = { item, index in
            
            switch index {
            case 0:
                let userListController = postsFeedStoryboard.instantiateViewController(withIdentifier: UserListViewController.identifier) as! UserListViewController
                userListOptionController.navigationController?.pushViewController(userListController, animated: true)
                
            case 1:
                // Show default user view
                let individualUserController = UIHostingController(rootView: UserQueryView())
                userListOptionController.navigationController?.pushViewController(individualUserController, animated: true)
                
            case 2:
                let permissionController = UIHostingController(rootView: UserPermissionView(channelId: nil))
                userListOptionController.navigationController?.pushViewController(permissionController, animated: true)
                
            case 3:
                let followingListController = postsFeedStoryboard.instantiateViewController(withIdentifier: FollowListViewController.identifier) as! FollowListViewController
                followingListController.pageType = .following
                userListOptionController.navigationController?.pushViewController(followingListController, animated: true)
                
            case 4:
                let followingListController = postsFeedStoryboard.instantiateViewController(withIdentifier: FollowListViewController.identifier) as! FollowListViewController
                followingListController.pageType = .follower
                userListOptionController.navigationController?.pushViewController(followingListController, animated: true)
                
            default:
                break
            }
        }
        userListOptionController.tabBarItem = UITabBarItem(title: "User List", image: UIImage(named: "ic_tab_users"), tag: 2)
        
        // Community Selection Screen
        let communitiesListController = ListViewController()
        communitiesListController.listTitle = "Communities"
        communitiesListController.items = ["Default","Trending", "Recommended"].map{ ListItem(id: $0, title: $0)}
        communitiesListController.listItemTapAction = { item, index in
            
            var communityType: CommunityType = .normal
            switch index {
            case 0:
                communityType = .normal
            case 1:
                communityType = .trending
            case 2:
                communityType = .recommended
            default:
                break
            }
            
            let communityController = UIHostingController(rootView: CommunityView(viewModel: CommunityListViewModel(type: communityType)))
            communitiesListController.navigationController?.pushViewController(communityController, animated: true)
        }
        communitiesListController.tabBarItem = UITabBarItem(title: "Communities", image: UIImage(named: "tab_comm"), tag: 3)
        
        var controllers = [homeController, postListController, userListOptionController, communitiesListController]
        
        let testController = TestController()
        testController.tabBarItem = UITabBarItem(title: "Test", image: UIImage(systemName: "note"), tag: 4)
        controllers.append(testController)
        
        // Tabs
        controllers = controllers.map{
            
            let navController = UINavigationController(rootViewController: $0)
            navController.tabBarItem = $0.tabBarItem
            return navController
        }
        
        viewControllers = controllers
    }
}

struct SwiftUIMainTabView: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = MainTabViewController
    
    func makeUIViewController(context: Context) -> MainTabViewController {
        let dashboardController = MainTabViewController()
        dashboardController.modalPresentationStyle = .fullScreen
        
        return dashboardController
    }
    
    func updateUIViewController(_ uiViewController: MainTabViewController, context: Context) {
        // Left empty
    }
}
