//
//  SignupViewController.swift
//  CLF-Chat
//
//  Created by Admin on 11/08/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtFirstName: UITextField!
    @IBOutlet weak var txtLastName: UITextField!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var txtCompanyName: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirmPw: UITextField!
    @IBOutlet weak var lblCategory: UILabel!
    
    @IBOutlet weak var pickerView: UIView!
    @IBOutlet weak var picker: UIPickerView!
    
    var list = ["Concierge", "Restaurant/Company", "Consumer"]
    var relationIndex : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        txtEmail.delegate = self
        txtFirstName.delegate = self
        txtLastName.delegate = self
        txtPhone.delegate = self
        txtCompanyName.delegate = self
        txtPassword.delegate = self
        txtConfirmPw.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignupViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        pickerView.isHidden = true
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
        txtCompanyName.resignFirstResponder()
        txtPassword.resignFirstResponder()
        txtConfirmPw.resignFirstResponder()
    }
    
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionRegister(_ sender: Any) {
        
        if validateInput() {
            
            let username = self.txtEmail.text!
            let email = self.txtEmail.text!
            let firstname = self.txtFirstName.text!
            let lastname = self.txtLastName.text!
            let mobile = self.txtPhone.text!
            let company = self.txtCompanyName.text!
            let password = self.txtPassword.text!
            let accountRequest = self.lblCategory.text!
            
            let paramsDict: Dictionary<String, AnyObject> = [
                "Username": username as AnyObject,
                "Email": email as AnyObject,
                "Fname": firstname as AnyObject,
                "Lname": lastname as AnyObject,
                "Mobile": mobile as AnyObject,
                "Company": company as AnyObject,
                "Password": password as AnyObject,
                "placeID": "-1" as AnyObject,
                "conciergeID": "-1" as AnyObject,
                "accountType": "" as AnyObject,
                "accountRequest": accountRequest as AnyObject
            ]

            print("Register params: \(paramsDict)")
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
        
        if lblCategory.text?.length == 0 {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "Please select category")
            return false
        }
        
        if txtCompanyName.text?.length == 0 {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "Please enter company name")
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
    
    @IBAction func actionSelCategory(_ sender: Any) {
        pickerView.isHidden = false
    }
    
    @IBAction func actionDone(_ sender: Any) {
        pickerView.isHidden = true
        
        lblCategory.text = list[relationIndex]
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return list.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return list[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        relationIndex = row
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
