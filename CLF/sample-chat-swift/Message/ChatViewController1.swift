//
//  SignupViewController.swift
//  CLF-Chat
//
//  Created by Admin on 11/08/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class ChatViewController1: UIViewController {
    
    @IBOutlet weak var txtMessage: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionAttach(_ sender: Any) {
        
    }
    
    @IBAction func actionSend(_ sender: Any) {
        
    }
    
    @IBAction func actionDelete(_ sender: Any) {
        
    }
    
    @IBAction func actionAddGroup(_ sender: Any) {
        
    }
    
}
