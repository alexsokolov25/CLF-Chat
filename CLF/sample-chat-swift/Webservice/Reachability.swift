//
//  Reachability.swift
//  Snapcart
//
//  Created by iOSDevStar on 11/8/15.
//  Copyright © 2015 Snapcart. All rights reserved.
//

import Foundation
import SystemConfiguration

open class Reachability {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        print("TODO: Fix Reachability.isConnectedToNetwork()")
        return true
    }
}
