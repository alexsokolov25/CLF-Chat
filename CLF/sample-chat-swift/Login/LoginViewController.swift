//
//  ViewController.swift
//  CLF-Chat
//
//  Created by Admin on 11/08/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        txtUsername.delegate = self
        txtPassword.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismissKeyboard()
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        txtUsername.resignFirstResponder()
        txtPassword.resignFirstResponder()
    }

    @IBAction func actionLogin(_ sender: Any) {
        
        if validateInput() {
            
            let username = self.txtUsername.text!
            let password = self.txtPassword.text!
            
            let paramsDict: Dictionary<String, AnyObject> = [
                "username": username as AnyObject,
                "password": password as AnyObject,
                "grant_type": "password" as AnyObject
            ]
            
            print("Login params: \(paramsDict)")
            LoadingOverlay.shared.showOverlay(self.view)
            
            WebServiceAPI.postDataWithURL(Constants.APINames.Login, token: nil,
                                          withoutHeader: true,
                                          params: paramsDict, completionBlock:
                {(request, response, json)->Void in
                    
                    
                    print("Successfully logged in to our server")
                    
                    if let responseJSON = JSON(json).dictionary {
                        
                        if let token = responseJSON["access_token"]?.string {
                            print("Found access token: \(token)")
                            
                            TheGlobalPoolManager.accessToken = token
                            
                            let getUserDetailsAPI_link : String = Constants.APINames.GetUserDetails + username
                            
                            WebServiceAPI.getDataWithURL(getUserDetailsAPI_link, token: token, params: nil, withoutHeader: false, cacheKey: nil, completionBlock:
                                {(request, response, json, false)->Void in
                                    
                                if let responseJSON = json.dictionary {
                                    
                                    if var userinfo = responseJSON["userInfo"]?.dictionary {
                                        
                                        print("userInfor: \(userinfo)")
                                        
                                        if userinfo["chatID"]?.string == "" {
                                        
                                            print("QuickBlox did not have this account yet, begin signUp with them")
                                        
                                            let quickblox_password = "4GM@k3$G*S"
                                            let fullname : String = String.init(format: "%@ %@", (userinfo["fname"]?.string)!, (userinfo["lname"]?.string)!)
                                        
                                            ServicesManager.instance().signup(username, email: (userinfo["email"]?.string)!, password: quickblox_password, fullname: fullname, completionBlock: { (response, user) -> Void in
                                                
                                                print("Finished sign up with QuickBlox with response: \(response) and user: \(user)")
                                                print("Begin signUpRequest with our app")

                                                let paramsDict: Dictionary<String, AnyObject> = [
                                                    "username": username as AnyObject,
                                                    "profileID": userinfo["profileID"] as AnyObject,
                                                    "chatID": user?.id as AnyObject
                                                ]
                                                
                                                WebServiceAPI.postDataWithURL(Constants.APINames.UpdateChatID, token: token,
                                                                              withoutHeader: false,
                                                                              params: paramsDict, completionBlock:
                                                    {(request, response, json)->Void in
                                                        
                                                        userinfo["chatID"]?.uInt = user?.id
                                                        
                                                        let userPlaces = responseJSON["userPlaces"]?.array
                                                        let place_count : Int = (userPlaces?.count)!
                                                        var placename : String = ""
                                                        if place_count > 0 {
                                                            let first_dic = userPlaces?[0].dictionary
                                                            let firstPlaceID = first_dic?["placeID"]?.int!
                                                            placename = (first_dic?["placeName"]?.string)!
                                                            TheGlobalPoolManager.placeID =  "\(firstPlaceID!)"
                                                        } else {
                                                            TheGlobalPoolManager.placeID = "-1"
                                                        }
                                                        
                                                        let userConcierge = responseJSON["userConcierge"]?.array
                                                        let concierge_count : Int = (userConcierge?.count)!
                                                        if concierge_count > 0 {
                                                            let concierge_dic = userConcierge?[0].dictionary
                                                            let firstConciergeID = concierge_dic?["conciergeID"]?.int
                                                            TheGlobalPoolManager.conciergeID = String(describing: firstConciergeID)
                                                        } else {
                                                            TheGlobalPoolManager.conciergeID = "-1"
                                                        }
                                                        
                                                        do {
                                                            let user = try User(fromJSON: userinfo, placename: placename)
                                                            TheGlobalPoolManager.currentUser = user
                                                            
                                                            self.loginToVideoCallService(nil)
                                                            
                                                        } catch {
                                                            print("ERROR: failed to initialize user after login: \(error)")
                                                        }
                                                        
                                                }, errBlock: {(errorString) -> Void in
                                                    TheInterfaceManager.showLocalValidationError(self, errorMessage: errorString)
                                                    LoadingOverlay.shared.hideOverlayView()
                                                })
                                            }, errBlock: { (response) -> Void in
                                                TheInterfaceManager.showLocalValidationError(self, errorMessage: "An error occurred while trying to register for video calling service")
                                                LoadingOverlay.shared.hideOverlayView()
                                            })
                                            
                                        } else {
                                            
                                            let userPlaces = responseJSON["userPlaces"]?.array
                                            let place_count : Int = (userPlaces?.count)!
                                            var placename : String = ""
                                            if place_count > 0 {
                                                let first_dic = userPlaces?[0].dictionary
                                                let firstPlaceID = first_dic?["placeID"]?.int!
                                                placename = (first_dic?["placeName"]?.string)!
                                                TheGlobalPoolManager.placeID =  "\(firstPlaceID!)"
                                            } else {
                                                TheGlobalPoolManager.placeID = "-1"
                                            }
                                            
                                            let userConcierge = responseJSON["userConcierge"]?.array
                                            let concierge_count : Int = (userConcierge?.count)!
                                            if concierge_count > 0 {
                                                let concierge_dic = userConcierge?[0].dictionary
                                                let firstConciergeID = concierge_dic?["conciergeID"]?.int
                                                TheGlobalPoolManager.conciergeID = String(describing: firstConciergeID)
                                            } else {
                                                TheGlobalPoolManager.conciergeID = "-1"
                                            }
                                            
                                            do {
                                                let user = try User(fromJSON: userinfo, placename: placename)
                                                TheGlobalPoolManager.currentUser = user
                                                
                                                self.loginToVideoCallService(nil)
                                                
                                            } catch {
                                                print("ERROR: failed to initialize user after login: \(error)")
                                            }
                                        }
                                    }
                                }
                                    
                            }, errBlock: {(errorString) -> Void in
                                TheInterfaceManager.showLocalValidationError(self, errorMessage: errorString)
                                LoadingOverlay.shared.hideOverlayView()
                            })
                            
                        } else {
                            print("ERROR: Failed to find access token")
                            //                        throw NetworkObjectError.missingAccessToken
                        }
                        
                }
                    
            }, errBlock: {(errorString) -> Void in
                TheInterfaceManager.showLocalValidationError(self, errorMessage: errorString)
                LoadingOverlay.shared.hideOverlayView()
            })
        }
    }
    
    @IBAction func actionSignup(_ sender: Any) {
        let viewCon = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController")
        self.navigationController?.pushViewController(viewCon!, animated: true)
    }
    
    func validateInput() -> Bool {
        
        if txtUsername.text?.length == 0 {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "Please enter username")
            return false
        }
        
        if txtPassword.text?.length == 0 {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage:"Please enter password")
            return false
        }
        
        return true
    }
    
    func loginToVideoCallService(_ completion: ((_ bSuccess: Bool, _ error: Error?) -> Void)?) {
        
        //quickblox login
        if let user = TheGlobalPoolManager.currentUser {
            
            let currentUser:QBUUser = QBUUser()
            currentUser.id = user.chatID
            currentUser.email = user.email
            currentUser.password = "4GM@k3$G*S"
            
            ServicesManager.instance().logIn(with: currentUser, completion:{
                [unowned self] (success, errorMessage) -> Void in
                
                guard success else {
                    TheInterfaceManager.showLocalValidationError(self, errorMessage: errorMessage!)
                    return
                }
                
                LoadingOverlay.shared.hideOverlayView()
                
                self.registerForRemoteNotification()
                
                self.loadUsersWithCompletion(completion: { (users) -> Void in
                    
                    TheGlobalPoolManager.allUsers = users!
                    
                    let viewCon = self.storyboard?.instantiateViewController(withIdentifier: "HomeViewController")
                    self.navigationController?.pushViewController(viewCon!, animated: true)
                })
            })
            
        }
        
    }
    
    func registerForRemoteNotification() {
        // Register for push in iOS 8
        if #available(iOS 8.0, *) {
            let settings = UIUserNotificationSettings(types: [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
        else {
            // Register for push in iOS 7
            UIApplication.shared.registerForRemoteNotifications(matching: [UIRemoteNotificationType.badge, UIRemoteNotificationType.sound, UIRemoteNotificationType.alert])
        }
    }
    
    // MARK: - Text Field Methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField.text!.isEmpty {
            return false
        }
        
        textField.resignFirstResponder()
        
        if textField == txtUsername {
            txtPassword?.becomeFirstResponder()
        }
        else if textField == txtPassword {
            self.dismissKeyboard()
        }
        
        return true
    }

    // MARK: - get quickblox all user
    
    func loadUsersWithCompletion(completion: @escaping ((_ results: [QBUUser]?)->Void)) {
        let responsePage: QBGeneralResponsePage = QBGeneralResponsePage(currentPage: 0, perPage: 100)
        QBRequest.users(for: responsePage, successBlock: { (response, responsePage, users) in
            print("users received: \(users)")
            completion(users)
            
        }) { (response) in
            print("error with users response: \(response.error)")
        }
    }
}

