//
//  MasterViewController.swift
//  Chat
//
//  Created by Victor Hugo Carvalho Barros on 2018-04-05.
//  Copyright © 2018 Kinvey. All rights reserved.
//

import UIKit
import Kinvey
import SVProgressHUD
import PromiseKit

class MasterViewController: UITableViewController {

    var detailViewController: ChatViewController? = nil
    var users = [User]() {
        didSet {
            guard !isEditing else {
                return
            }
            tableView.reloadData()
        }
    }
    
    var activeUserPromise: Promise<User>! {
        didSet {
            activeUserPromise = activeUserPromise.then { (user) -> Promise<User> in
                self.navigationItem.prompt = "UserId: \(user.userId) Username: \(user.username ?? "")"
                return Promise(value: user)
            }.catch {
                SVProgressHUD.showError(withStatus: $0.localizedDescription)
            }
        }
    }
    
    lazy var dataStore: DataStore<Message> = {
        return DataStore<Message>.collection(.network)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newChat(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? ChatViewController
        }
        
        if let refreshControl = refreshControl {
            refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
            refresh(refreshControl)
        }
    }
    
    @objc
    func refresh(_ sender: Any) {
        activeUserPromise.then { _ in
            return self.loadUsers()
        }.then{
            return self.loadUsers(results: $0)
        }.then {
            self.users = $0
        }.always {
            self.refreshControl?.endRefreshing()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    func loadUsers() -> Promise<[(Message, JsonDictionary)]> {
        SVProgressHUD.show()
        return Promise<[(Message, JsonDictionary)]> { fulfill, reject in
            dataStore.group(
                keys: [
                    "_acl.r",
                    "_acl.creator"
                ],
                initialObject: [:],
                reduceJSFunction: """
function(doc, out) {
    if (out.max == undefined || out.max == null || doc._kmd.lmt > out.max) {
        out.max = doc._kmd.lmt;
    }
}
""",
                options: nil
            ) {
                switch $0 {
                case .success(let results):
                    fulfill(results)
                case .failure(let error):
                    reject(error)
                }
            }
        }.always {
            SVProgressHUD.dismiss()
        }.catch {
            SVProgressHUD.showError(withStatus: $0.localizedDescription)
        }
    }
    
    func loadUsers(results: [(Message, JsonDictionary)]) -> Promise<[User]> {
        SVProgressHUD.show()
        return Promise<[User]> { fulfill, reject in
            let activeUser = Kinvey.sharedClient.activeUser!
            let dateTransform = KinveyDateTransform()
            let sequence = results.compactMap { (message, json) -> (String, Date)? in
                guard let creator = json["_acl.creator"] as? String,
                    let readers = json["_acl.r"] as? [String],
                    let reader = readers.first,
                    let max = json["max"] as? String,
                    let date = dateTransform.transformFromJSON(max)
                else {
                    return nil
                }
                return (activeUser.userId == creator ? reader : creator, date)
            }
            let userIdAndLastMessageDate = Dictionary<String, Date>(sequence, uniquingKeysWith: { (date1, date2) -> Date in
                return max(date1, date2)
            })
            let query = Query(format: "_id IN %@", Array(userIdAndLastMessageDate.keys))
            activeUser.find(query: query, options: nil) {
                SVProgressHUD.dismiss()
                switch $0 {
                case .success(let users):
                    fulfill(users)
                case .failure(let error):
                    reject(error)
                }
            }
        }.always {
            SVProgressHUD.dismiss()
        }.catch {
            SVProgressHUD.showError(withStatus: $0.localizedDescription)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    enum Segue: String {
        
        case users
        case showDetail
        
    }

    @objc
    func newChat(_ sender: Any) {
        performSegue(withIdentifier: Segue.users.rawValue, sender: sender)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch Segue(rawValue: segue.identifier!)! {
        case .showDetail:
            if let indexPath = tableView.indexPathForSelectedRow {
                let user = users[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! ChatViewController
                controller.user = user
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        case .users:
            isEditing = false
            let controller = segue.destination as! UsersTableViewController
            controller.excludeUsers = Set(users)
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let user = users[indexPath.row]
        cell.textLabel?.text = user.username
        cell.detailTextLabel?.text = user.userId
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            users.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    @IBAction
    func unwindToMainViewController(segue: UIStoryboardSegue) {
    }

}

