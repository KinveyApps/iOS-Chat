//
//  Message.swift
//  Chat
//
//  Created by Victor Hugo Carvalho Barros on 2018-04-05.
//  Copyright © 2018 Kinvey. All rights reserved.
//

import Kinvey

class Message: Entity {
    
    @objc
    dynamic var text: String?
    
    override class func collectionName() -> String {
        return "Message"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        text <- ("text", map["text"])
    }
    
}
