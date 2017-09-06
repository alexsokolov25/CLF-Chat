//
//  SignupViewController.swift
//  CLF-Chat
//
//  Created by Admin on 11/08/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class AddNewUserViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtFirstName: UITextField!
    @IBOutlet weak var txtLastName: UITextField!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirmPw: UITextField!
    
    @IBOutlet weak var imgOn: UIImageView!
    @IBOutlet weak var imgOff: UIImageView!
    
    var accountType : String = "Manager"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        txtEmail.delegate = self
        txtFirstName.delegate = self
        txtLastName.delegate = self
        txtPhone.delegate = self
        txtPassword.delegate = self
        txtConfirmPw.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AddNewUserViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        imgOn.image = UIImage(named: "ic_radio_on")
        imgOff.image = UIImage(named: "ic_radio_off")
        
        self.view.layoutIfNeeded()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismissKeyboard()
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        txtEmail.resignFirstResponder()
        txtFirstName.resignFirstResponder()
        txtLastName.resignFirstResponder()
        txtPhone.resignFirstResponder()
        txtPassword.resignFirstResponder()
        txtConfirmPw.resignFirstResponder()
    }
    
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionCreateUser(_ sender: Any) {
        
        if validateInput() {
            let username = self.txtEmail.text!
            let email = self.txtEmail.text!
            let firstname = self.txtFirstName.text!
            let lastname = self.txtLastName.text!
            let mobile = self.txtPhone.text!
            let password = self.txtPassword.text!
            
            let placeID : String = TheGlobalPoolManager.placeID
            let conciergeID : String = TheGlobalPoolManager.conciergeID
            
            let paramsDict: Dictionary<String, AnyObject> = [
                "Username": username as AnyObject,
                "Email": email as AnyObject,
                "Fname": firstname as AnyObject,
                "Lname": lastname as AnyObject,
                "Mobile": mobile as AnyObject,
                "Company": "" as AnyObject,
                "Password": password as AnyObject,
                "placeID": placeID as AnyObject,
                "conciergeID": conciergeID as AnyObject,
                "accountType": accountType as AnyObject,
                "accountRequest": "" as AnyObject
            ]
            
            print("Invite User params: \(paramsDict)")
            LoadingOverlay.shared.showOverlay(self.view)
            
            WebServiceAPI.postDataWithURL(Constants.APINames.CreateUser, token: nil,
                                          withoutHeader: true,
                                          params: paramsDict, completionBlock:
                {(request, response, json)->Void in
                    
                    
                    print("Successfully register to our server")
                    
                    if let responseJSON = JSON(json).dictionary {
                        
                        let response = responseJSON["response"]?.string
                        
                        if response == "success" {
                            
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            print("ERROR: failed to register")
                        }
                    }
                    
            }, errBlock: {(errorString) -> Void in
                TheInterfaceManager.showLocalValidationError(self, errorMessage: errorString)
                LoadingOverlay.shared.hideOverlayView()
            })
        }
    }
    
    func validateInput() -> Bool {
        
        if txtEmail.text?.length == 0 {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "Please enter email")
            return false
        }
        
        if !(txtEmail.text?.isEmailValid)! {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "Please enter email correctly")
            return false
        }
        
        if txtFirstName.text?.length == 0 {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "Please enter first name")
            return false
        }
        
        if txtLastName.text?.length == 0 {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "Please enter last name")
            return false
        }
        
        if txtPhone.text?.length == 0 {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "Please enter phone number")
            return false
        }
        
        if txtPassword.text?.length == 0 {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage:"Please enter password")
            return false
        }
        
//        if (txtPassword.text?.length)! < 8  {
//            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage:"Password length should be 8 characters as minimum!")
//            return false
//        }
//        
//        if (txtConfirmPw.text?.length)! < 8  {
//            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage:"Please enter confirm password!")
//            return false
//        }
        
        if self.txtPassword.text != self.txtConfirmPw.text {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage:"Please confirm password correctly!")
            return false
        }
        
        return true
    }
    
    @IBAction func actionSelPermission(_ sender: UIButton) {
        if sender.tag == 10 {
            
            accountType = "Manager"
            
            imgOn.image = UIImage(named: "ic_radio_on")
            imgOff.image = UIImage(named: "ic_radio_off")
        } else {
            
            accountType = "User"
            
            imgOn.image = UIImage(named: "ic_radio_off")
            imgOff.image = UIImage(named: "ic_radio_on")
        }
    }
    
    // MARK: - Text Field Methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField.text!.isEmpty {
            return false
        }
        
        textField.resignFirstResponder()
        
        if textField == txtEmail {
            txtFirstName?.becomeFirstResponder()
        }
        else if textField == txtFirstName {
            txtLastName?.becomeFirstResponder()
        }
        else if textField == txtLastName {
            txtPhone?.becomeFirstResponder()
        }
        else if textField == txtPhone {
            txtPassword?.becomeFirstResponder()
        }
        else if textField == txtPassword {
            txtConfirmPw?.becomeFirstResponder()
        }
        else if textField == txtConfirmPw {
            self.dismissKeyboard()
        }
        
        return true
    }
}
