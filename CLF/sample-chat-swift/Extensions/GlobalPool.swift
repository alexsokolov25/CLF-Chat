//
//  GlobalPool.swift
//  READY
//
//  Created by Admin on 22/03/16.
//  Copyright © 2016 Siochain. All rights reserved.
//

import UIKit

let TheGlobalPoolManager = GlobalPool.sharedInstance

class GlobalPool: NSObject {
    static let sharedInstance = GlobalPool()

    var currentUser: User? = nil
    
    var accessToken: String = ""
    var placeID: String = ""
    var conciergeID: String = ""
    
    var bCallerUser: Bool = false
    
    var allUsers : [QBUUser] = []
    
    override init() {
        super.init()
    }
    
    func getQUserName(chatID : UInt) -> String {
        
        for elem in self.allUsers {
            
            if elem.id == chatID {
                return elem.fullName!
            }
        }
        
        return ""
    }
    
    func getQUser(chatID : UInt) -> QBUUser {
        
        for elem in self.allUsers {
            
            if elem.id == chatID {
                return elem
            }
        }
        
        return QBUUser()
    }
}
