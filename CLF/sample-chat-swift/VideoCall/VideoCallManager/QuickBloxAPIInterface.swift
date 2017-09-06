//
//  QuickBloxAPIInterface.swift
//  VideoChat
//
//  Created by Admin on 29/02/16.
//  Copyright © 2016 RonnieAlex. All rights reserved.
//

import UIKit

let TheQuickBloxAPIInterface = QuickBloxAPIInterface.sharedInstance

class QuickBloxAPIInterface: NSObject{
    static let sharedInstance = QuickBloxAPIInterface()
    
    var currentUser: QBUUser? = nil
    
    override init() {
        super.init()
    }

    func initProcess() {
        QBSettings.setApplicationID(Constants.QuickBlox.AppID)
        QBSettings.setAuthKey(Constants.QuickBlox.AuthKey)
        QBSettings.setAuthSecret(Constants.QuickBlox.AuthSecret)
        QBSettings.setAccountKey(Constants.QuickBlox.AccountKey)

        QBSettings.setLogLevel(.info)
        QBSettings.setAutoReconnectEnabled(true)
        
        // enabling carbons for chat
        QBSettings.setCarbonsEnabled(true)
        
        // Enables detailed XMPP logging in console output.
        QBSettings.enableXMPPLogging()
    }
    
    func login(_ ID: String,
        email: String,
        password: String,
        completionBlock:((_ response:QBResponse, _ user:QBUUser?)->Void)?,
        errBlock:((_ response:QBResponse)->Void)? )-> Void {
            let currentUser:QBUUser = QBUUser()
            //currentUser.login = ID
            currentUser.email = email
            currentUser.password = password
            
            QBRequest.logIn(withUserEmail: currentUser.email!, password: currentUser.password!, successBlock: { (response, user) -> Void in
                    self.currentUser = user
                    completionBlock!(response, user)
                },
                errorBlock: { (response) -> Void in
                    errBlock!(response)
                }
            )
    }

    func logout(_ completionBlock:((_ response:QBResponse)->Void)?,
        errBlock:((_ response:QBResponse)->Void)? )-> Void {
            QBRequest.logOut(successBlock: { (response) -> Void in
                    completionBlock!(response)
                },
                errorBlock: { (response) -> Void in
                    errBlock!(response)
                }
            )
    }

    func signup(_ ID: String,
        email: String,
        password: String,
        fullname: String,
        completionBlock:((_ response:QBResponse, _ user:QBUUser?)->Void)?,
        errBlock:((_ response:QBResponse)->Void)? )-> Void {
            let currentUser:QBUUser = QBUUser()
            currentUser.login = ID
            currentUser.email = email
            currentUser.fullName = fullname
            currentUser.password = password

            QBRequest.signUp(currentUser, successBlock: { (response, user) -> Void in
                    completionBlock!(response, user)
                },
                errorBlock: { (response) -> Void in
                    print("%@", response.error?.description)
                    
                    errBlock!(response)
                }
            )
    }

    func checkExsitingAccount(_ email : String,
                              completionBlock:@escaping ((_ bExisting:Bool, _ userID: UInt?)->Void) ) -> Void {

        print("QB checking existing account with email: \(email)")
        QBRequest.user(withEmail: email,successBlock: { (response, user) -> Void in
                print("QB: Email '\(email)' already exists")
                completionBlock(true, user.id)
            },
            errorBlock: { (response) -> Void in
                print("QB: Email '\(email)' does not yet exist")
                completionBlock(false, nil)
            }
        )
        
    }
}
