//
//  ChatTableViewController.swift
//  Chat
//
//  Created by Victor Hugo Carvalho Barros on 2018-04-05.
//  Copyright © 2018 Kinvey. All rights reserved.
//

import UIKit
import Kinvey
import SVProgressHUD

class MessagesTableViewController: UITableViewController {
    
    var user: User! {
        didSet {
            dataStore.find(query, options: nil) { (result: Result<AnyRandomAccessCollection<Message>, Swift.Error>) in
                switch result {
                case .success(let messages):
                    self.messages = messages
                case .failure(let error):
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                }
            }
        }
    }
    
    var messages: AnyRandomAccessCollection<Message> = AnyRandomAccessCollection([]) {
        didSet {
            guard !isEditing else {
                return
            }
            tableView.reloadData()
        }
    }
    
    lazy var dataStore: DataStore<Message> = {
        return DataStore<Message>.collection(.sync)
    }()
    
    var query: Query {
        return Query(format: "(acl.readers IN %@) OR (acl.creator == %@)", user.userId, user.userId)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        if let refreshControl = refreshControl {
            refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
            refresh(refreshControl)
        }
    }
    
    @objc
    func refresh(_ sender: Any) {
        dataStore.find(query, options: nil) { (result: Result<AnyRandomAccessCollection<Message>, Swift.Error>) in
            switch result {
            case .success(let messages):
                self.messages = messages
            case .failure(let error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
        dataStore.pull(query, options: nil) {
            self.refreshControl?.endRefreshing()
            
            switch $0 {
            case .success(let messages):
                self.messages = messages
            case .failure(let error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let activeUser = Kinvey.sharedClient.activeUser else {
            return
        }
        activeUser.registerForRealtime {
            switch $0 {
            case .success:
                SVProgressHUD.showInfo(withStatus: "User registered for Realtime")
                
                self.subscribeToListenForNewMessages()
            case .failure(let error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let activeUser = Kinvey.sharedClient.activeUser else {
            return
        }
        dataStore.unsubscribe {
            switch $0 {
            case .success:
                activeUser.unregisterForRealtime {
                    switch $0 {
                    case .success:
                        break
                    case .failure(let error):
                        SVProgressHUD.showError(withStatus: error.localizedDescription)
                    }
                }
            case .failure(let error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    func subscribeToListenForNewMessages() {
        dataStore.subscribe(
            userId: user.userId,
        subscription: {
            SVProgressHUD.showInfo(withStatus: "Waiting for new messages")
            SVProgressHUD.dismiss(withDelay: 0.5)
        }, onNext: {
            let newMessages: [AnyRandomAccessCollection<Message>]
            if let index = self.messages.index(of: $0) {
                let begin = self.messages[self.messages.startIndex ..< index]
                let end = self.messages[self.messages.index(index, offsetBy: 1) ..< self.messages.endIndex]
                newMessages = [begin, AnyRandomAccessCollection([$0]), end]
            } else {
                newMessages = [self.messages, AnyRandomAccessCollection([$0])]
            }
            self.messages = AnyRandomAccessCollection(newMessages.lazy.flatMap { $0 })
        }, onStatus: { status in
            switch status {
            case .connected:
                SVProgressHUD.showInfo(withStatus: "Connected")
                SVProgressHUD.dismiss(withDelay: 0.5)
            case .disconnected:
                SVProgressHUD.showInfo(withStatus: "Disconnected")
            case .reconnected:
                SVProgressHUD.showInfo(withStatus: "Reconnected")
            case .unexpectedDisconnect:
                SVProgressHUD.showInfo(withStatus: "Unexpected Disconnect")
            }
        }, onError: { error in
            SVProgressHUD.showError(withStatus: error.localizedDescription)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return messages.count
    }
    
    enum CellReuseIdentifier: String {
        
        case leftReuseIdentifier
        case rightReuseIdentifier
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let reuseIdentifier: CellReuseIdentifier = message.acl?.creator == user.userId ? .leftReuseIdentifier : .rightReuseIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier.rawValue, for: indexPath) as! MessageTableViewCell

        // Configure the cell...
        cell.message = message

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
