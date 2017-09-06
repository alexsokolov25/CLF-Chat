//
//  IncomingCallViewController.swift
//  VideoChat
//
//  Created by Admin on 01/03/16.
//  Copyright © 2016 RonnieAlex. All rights reserved.
//

import UIKit

class IncomingCallViewController: UIViewController, VideoCallManagerDelegate {
    
    @IBOutlet weak var m_imageViewOpponentUser: UIImageView!
    @IBOutlet weak var m_lblOpponentUserName: UILabel!
    @IBOutlet weak var m_btnEndCall: UIButton!
    @IBOutlet weak var m_btnAcceptCall: UIButton!

    var strOpponentUserName: String = ""
    var strOpponentUserProfileUrl: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge()
       
        // Do any additional setup after loading the view.
    }
    @IBOutlet weak var backgroundView: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        TheVideoCallManager.delegate = self

        self.makeUserInterface()
        
        TheVideoCallManager.incomingCall()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        TheVideoCallManager.delegate = nil
    }
    
    func makeUserInterface() {
        self.m_lblOpponentUserName.text = "Calling from \(self.strOpponentUserName)"
        
        m_imageViewOpponentUser.setNeedsLayout()
        m_imageViewOpponentUser.layoutIfNeeded()
        self.m_imageViewOpponentUser.downloadedFrom(self.strOpponentUserProfileUrl, contentMode:.scaleAspectFit)
        
        backgroundView.setNeedsLayout()
        backgroundView.layoutIfNeeded()
        self.backgroundView.downloadedFrom(self.strOpponentUserProfileUrl, contentMode:.scaleAspectFit)
    }
    
    override func viewDidLayoutSubviews() {
        InterfaceManager.makeRadiusControl(self.m_imageViewOpponentUser, cornerRadius: self.m_imageViewOpponentUser.bounds.width * 0.5, withColor: Constants.Colors.naviTintColor, borderSize: 0.0)

        InterfaceManager.makeRadiusControl(self.m_btnEndCall, cornerRadius: self.m_btnEndCall.bounds.size.width * 0.5, withColor: UIColor.white, borderSize: 0.0)
        InterfaceManager.makeRadiusControl(self.m_btnAcceptCall, cornerRadius: self.m_btnAcceptCall.bounds.size.width * 0.5, withColor: UIColor.white, borderSize: 0.0)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func actionEndCall(_ sender: AnyObject) {
        TheVideoCallManager.rejectCall(TheVideoCallManager.currentSession)
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func actionAcceptCall(_ sender: AnyObject) {
        self.goVideoCallView()
    }

    func goVideoCallView() {
        let viewCon: VideoCallViewController = self.storyboard?.instantiateViewController(withIdentifier: "videocallview") as! VideoCallViewController
        viewCon.bOutComingCall = false
        
        self.addChildViewController(viewCon)
        self.view.addSubview(viewCon.view)
        viewCon.didMove(toParentViewController: self)
    }

    func callErrors(_ description: String) {
        self.endCallProcess()
    }
    
    func acceptedByUser() {
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == 100 {
            self.endCallProcess()
        }
    }

    func endCallProcess () {
        TheVideoCallManager.bIncomingCall = false

        self.dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
