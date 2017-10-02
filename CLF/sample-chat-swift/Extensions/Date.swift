//
//  Date.swift
//  READY
//
//  Created by Admin on 25/05/16.
//  Copyright © 2016 Siochain. All rights reserved.
//

import UIKit

extension Date {
    func covertToString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm a"
//        dateFormatter.timeZone = NSTimeZone(name: "UTC") as! TimeZone
        return dateFormatter.string(from: self)
    }
    
    func covertToString1() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy HH:mm a"
        //        dateFormatter.timeZone = NSTimeZone(name: "UTC") as! TimeZone
        return dateFormatter.string(from: self)
    }
}
