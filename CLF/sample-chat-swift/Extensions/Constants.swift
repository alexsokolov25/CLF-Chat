//
//  Constants.swift
//  Clinic
//
//  Created by Admin on 27/04/16.
//  Copyright © 2016 Yagor. All rights reserved.
//

import Foundation
import UIKit

let kChatPresenceTimeInterval:TimeInterval = 45
let kDialogsPageLimit:UInt = 100
let kMessageContainerWidthPadding:CGFloat = 40.0

public struct Constants {
    
    struct WebServiceApi {
        static let ApiBaseUrl = "http://clf1d7.galaxyclear.com/"
    }
    
    static var QB_USERS_ENVIROMENT: String {
        
        #if DEBUG
            return "dev"
        #elseif QA
            return "qbqa"
        #else
            assert(false, "Not supported build configuration")
            return ""
        #endif
        
    }
    
    struct QuickBlox {
        
        static let AppID: UInt = 61554
        static let AuthKey = "5M7r7cErDVuHLkJ"
        static let AuthSecret = "YNULjqeUL5OG8Ea"
        static let AccountKey = "nBT7zoes6uyS3sas-33K"
    }
    
    struct APINames {
        static let Login = "token"
        static let GetUserDetails = "api/chat/getUserDetails?username="
        static let CreateUser = "api/chat/RegisterUser"
        static let GroupMember = "api/chat/getGroupMembers?username=%@&placeID=%@&conciergeID=%@"
        static let AllContacts = "api/chat/getAllContacts?username=%@&placeID=%@&conciergeID=%@"
        static let UpdateChatID = "api/chat/updateChatID"
    }
    
    struct CellID {
        static let MessageHistoryCell = "MessageHistoryCell"
        static let ArchivedCell = "ArchivedCell"
        static let ContactCell = "ContactCell"
        static let UserCell = "UserCell"
    }
    
    struct Colors {
        static let Gold = UIColor(netHex: 0xFFCC33)
        static let Lavender = UIColor(netHex: 0x8400FF)
        static let Aqua = UIColor(netHex: 0xE8C52F)
        
        static let TextFieldBorder = UIColor(netHex: 0xE7E7E7)
        static let Greeen = UIColor(netHex: 0x7CC576)
        static let Orange = UIColor(netHex: 0xFBAE5C)
        static let Red = UIColor(netHex: 0xF26C4F)
        
        static let NaviColor = UIColor(netHex: 0xF5F5F5)
        static let OppenentChatColor = UIColor(netHex: 0xF5F5F5)
        static let MyChatColor = UIColor(netHex: 0x7CC576)
        
        static let ChatActionColor = UIColor(netHex: 0xBABABA)
        
        
        static let mainColor: UIColor = UIColor(red: 77.0/255.0, green: 181.0/255.0, blue: 219.0/255.0, alpha: 1.0)
        static let borderColor: UIColor = UIColor(red: 151.0 / 255.0, green: 151.0 / 255.0, blue: 151.0 / 255.0, alpha: 1.0)
        static let naviTintColor: UIColor = UIColor(red: 252.0/255.0, green: 110.0/255.0, blue: 81.0/255.0, alpha: 1.0)
    }
}
