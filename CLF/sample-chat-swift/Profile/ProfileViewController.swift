//
//  SignupViewController.swift
//  CLF-Chat
//
//  Created by Admin on 11/08/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var imgUserAvatar: UIImageView!
    @IBOutlet weak var lblFullName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var lblPhone: UILabel!
    @IBOutlet weak var lblCompany: UILabel!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblPassword: UILabel!
    
    var delegate : LogoutDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let user = TheGlobalPoolManager.currentUser
        
        lblFullName.text = "Full Name: " + (user?.fname)! + " " + (user?.lname)!
        lblEmail.text = "Email: " + (user?.email)!
        lblPhone.text = "Phone: " + (user?.mobile)!
        lblCompany.text = "Company: "
        lblUserName.text = "Username: " + (user?.username)!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionChangePassword(_ sender: Any) {
        
    }
    
    @IBAction func actionLogout(_ sender: Any) {
        
        let alertController = UIAlertController(title: "Logout", message: "Are you sure?", preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            
            if self.delegate != nil {
                self.delegate!.logout()
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(defaultAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
        
    }
    
}
