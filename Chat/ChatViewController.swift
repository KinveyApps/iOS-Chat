//
//  ChatViewController.swift
//  Chat
//
//  Created by Victor Hugo Carvalho Barros on 2018-04-05.
//  Copyright © 2018 Kinvey. All rights reserved.
//

import UIKit
import Kinvey
import SVProgressHUD

class ChatViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    
    var user: User! {
        didSet {
            navigationItem.title = user.username
            navigationItem.prompt = user.userId
        }
    }
    
    lazy var dataStore: DataStore<Message> = {
        return DataStore<Message>.collection(.network)
    }()
    
    var messagesTableViewController: MessagesTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        textField.inputAccessoryView = UIView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction
    func send(_ sender: Any) {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), text.count > 0 else {
            return
        }
        
        let message = Message()
        
        // Permissions can also be enforced using collection settings in the Kinvey Console
        let acl = Acl()
        acl.globalRead.value = false
        acl.globalWrite.value = false
        acl.readers = [user.userId]
        message.acl = acl
        
        message.text = text
        
        textField.text = nil
        textField.resignFirstResponder()
        
        SVProgressHUD.show()
        dataStore.save(message, options: nil) {
            SVProgressHUD.dismiss()
            switch $0 {
            case .success(_):
                guard let messagesTableViewController = self.messagesTableViewController else {
                    return
                }
                
                messagesTableViewController.isEditing = true
                let messages = [messagesTableViewController.messages, AnyRandomAccessCollection([message])]
                messagesTableViewController.messages = AnyRandomAccessCollection(messages.lazy.flatMap { $0 })
                messagesTableViewController.tableView.beginUpdates()
                messagesTableViewController.tableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .right)
                messagesTableViewController.tableView.endUpdates()
                messagesTableViewController.isEditing = false
                
                SVProgressHUD.showSuccess(withStatus: "Sent!")
                SVProgressHUD.dismiss(withDelay: 0.5)
            case .failure(let error):
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    enum Segue: String {
        
        case messages
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch Segue(rawValue: segue.identifier!)! {
        case .messages:
            messagesTableViewController = segue.destination as? MessagesTableViewController
            messagesTableViewController?.user = user
        }
    }

}
