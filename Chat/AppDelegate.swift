//
//  AppDelegate.swift
//  Chat
//
//  Created by Victor Hugo Carvalho Barros on 2018-04-05.
//  Copyright © 2018 Kinvey. All rights reserved.
//

import UIKit
import Kinvey
import SVProgressHUD
import IQKeyboardManagerSwift
import PromiseKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?
    
    var splitViewController: UISplitViewController {
        return window!.rootViewController as! UISplitViewController
    }
    
    var navigationController: UINavigationController {
        return splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
    }
    
    var masterViewController: MasterViewController {
        return (splitViewController.viewControllers.first as! UINavigationController).topViewController as! MasterViewController
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.sharedManager().enable = true
        
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        
        SVProgressHUD.show()
        
        Kinvey.sharedClient.logNetworkEnabled = true
        
        masterViewController.activeUserPromise = Promise<User> { fulfill, reject in
            Kinvey.sharedClient.initialize(
                appKey: "<#My App Key#>",
                appSecret: "<#My App Secret#>"
            ) {
                SVProgressHUD.dismiss()
                switch $0 {
                case .success(let user):
                    if let user = user {
                        fulfill(user)
                    } else {
                        SVProgressHUD.show()
                        User.signup(options: nil) {
                            SVProgressHUD.dismiss()
                            switch $0 {
                            case .success(let user):
                                fulfill(user)
                            case .failure(let error):
                                reject(error)
                            }
                        }
                    }
                case .failure(let error):
                    reject(error)
                }
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? ChatViewController else { return false }
        if topAsDetailController.user == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }

}

