//
//  MessageTableViewCell.swift
//  Chat
//
//  Created by Victor Hugo Carvalho Barros on 2018-04-05.
//  Copyright © 2018 Kinvey. All rights reserved.
//

import UIKit

let dateFormat: DateFormatter = {
    let dateFormat = DateFormatter()
    dateFormat.dateStyle = .long
    dateFormat.timeStyle = .long
    return dateFormat
}()

class MessageTableViewCell: UITableViewCell {
    
    var message: Message! {
        didSet {
            textMessageLabel.text = message.text
            if let creationTime = message.metadata?.entityCreationTime {
                dateMessageLabel.text = dateFormat.string(from: creationTime)
            } else {
                dateMessageLabel.text = nil
            }
        }
    }

    @IBOutlet
    weak var textMessageLabel: UILabel!
    
    @IBOutlet
    weak var dateMessageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
