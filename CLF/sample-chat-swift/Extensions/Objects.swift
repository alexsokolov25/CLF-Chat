//
//  Objects.swift
//  READY
//
//  Created by Admin on 26/05/16.
//  Copyright © 2016 Siochain. All rights reserved.
//

import Foundation
// import SwiftyJSON

protocol NetworkObject {
    
    init(fromJSON json: [String: JSON], placename: String) throws
    static var jsonID: String { get }
}

//class User: BaseEntity {
struct User: NetworkObject {
    var profileID : Int = 0
    var fname: String = ""
    var lname: String = ""
    var mobile: String = ""
    var email: String? = nil
    var chatID : UInt = 0
    var username: String = ""
    var password: String = ""
    
    static var jsonID: String = "users"

    init(fromJSON json: [String: JSON], placename: String) throws {
        
        if let strid = json["profileID"]?.int {
            let intid = Int(strid)
            self.profileID = intid
        }
        
        if let strfname = json["fname"]?.string {
            self.fname = strfname
        }
        
        if let strlname = json["lname"]?.string {
            self.lname = strlname
        }
        
        if let strmobile = json["mobile"]?.string {
            self.mobile = strmobile
        }
        
        if let stremail = json["email"]?.string {
            self.email = stremail
        }

        if let strchatID = json["chatID"]?.string {
            let intid = UInt(strchatID)
            self.chatID = intid!
        }
        
        if let strusername = json["username"]?.string {
            self.username = strusername
        }
    }
}

struct GroupMember: NetworkObject {
    
    let placename : String?
    let fname: String?
    let lname: String?
    let mobile: String?
    var profileID: Int = 0
    let chatID: String?
    
    let email: String?
    let username: String?
    let password: String?
    
    init(fromJSON json: [String: JSON], placename: String) {
        self.placename = placename
        self.fname = json["fname"]?.string
        self.lname = json["lname"]?.string
        self.mobile = json["mobile"]?.string
        
        if let profileID = json["profileID"]?.int {
            let intid = Int(profileID)
            self.profileID = intid
        }
        self.chatID = json["chatID"]?.string
        
        self.email = json["email"]?.string
        self.username = json["username"]?.string
        self.password = json["password"]?.string
        
    }
    
    static var jsonID: String = "people"
}


