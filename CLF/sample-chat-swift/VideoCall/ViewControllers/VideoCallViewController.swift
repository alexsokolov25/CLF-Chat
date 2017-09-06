//
//  VideoCallViewController.swift
//  VideoChat
//
//  Created by Admin on 25/02/16.
//  Copyright © 2016 RonnieAlex. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary

let kRefreshTimeInterval: TimeInterval = 1.0

class VideoCallViewController: UIViewController, OutComingCallViewControllerDelegate {
    @IBOutlet weak var m_opponentVideoView: QBRTCRemoteVideoView!
    @IBOutlet weak var m_myVideoView: UIView!
    
    @IBOutlet weak var connectingActivity: UIActivityIndicatorView!
    
    @IBOutlet weak var m_btnMuteSound: UIButton!
    @IBOutlet weak var m_btnEndCall: UIButton!
    @IBOutlet weak var m_btnSwitchCamera: UIButton!

    var bRecording: Bool = false
    
    var videoLayer: AVCaptureVideoPreviewLayer? = nil
    var cameraCapture: QBRTCCameraCapture? = nil

    var videoDeviceInput: AVCaptureDeviceInput?
    var audioDeviceInput: AVCaptureDeviceInput?
    var movieFileOutput = AVCaptureMovieFileOutput()

    let outputFilePath  = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("movie.mov")

    //variables for opponent user info
    var bOutComingCall: Bool = false
    var strOpponentUserName: String = ""
    var strOpponentUserProfileUrl: String = ""
    var opponentUserID: NSNumber? = nil
    //---------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge()
        
        // Do any additional setup after loading the view.
//        TheVideoCallManager.configureGUI()

        TheVideoCallManager.currentVideoCallViewCon = self
        
        if TheVideoCallManager.currentSession?.conferenceType == .video {
            self.cameraCapture = QBRTCCameraCapture(videoFormat: QBRTCVideoFormat.default(), position: .front)
            //setupVideoSaveSession()
            self.cameraCapture?.startSession()
            
            self.m_btnSwitchCamera.isHidden = false
            self.m_opponentVideoView.isHidden = false
            self.m_myVideoView.isHidden = false
        } else {
            self.m_btnSwitchCamera.isHidden = true
            self.m_opponentVideoView.isHidden = true
            self.m_myVideoView.isHidden = true
        }
        
        if bOutComingCall {
            TheVideoCallManager.startCall()
        } else {
            TheVideoCallManager.acceptCall()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        if bOutComingCall {
            //add outcoming view controller
            let viewCon: OutComingCallViewController = self.storyboard?.instantiateViewController(withIdentifier: "outcomingcallview") as! OutComingCallViewController
            viewCon.strOpponentUserName = self.strOpponentUserName
            viewCon.strOpponentUserProfileUrl = self.strOpponentUserProfileUrl
            viewCon.delegate = self
            
            self.addChildViewController(viewCon)
            self.view.addSubview(viewCon.view)
            viewCon.didMove(toParentViewController: self)
        }
    }
    
    func removeOutComingViewCon(_ viewCon: OutComingCallViewController) {
        viewCon.didMove(toParentViewController: nil)
        viewCon.view.removeFromSuperview()
        viewCon.removeFromParentViewController()
        
        self.adjustMyVideoView()
    }
    
    func setOpponentVideoView() {
        let remoteVideoTrack: QBRTCVideoTrack = (TheVideoCallManager.currentSession?.remoteVideoTrack(withUserID: TheVideoCallManager.opponentUserID!))!
        self.m_opponentVideoView.setVideoTrack(remoteVideoTrack)
    }
    
    func adjustMyVideoView() {
        if TheVideoCallManager.currentSession?.conferenceType == .video {
            self.cameraCapture?.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
            self.cameraCapture?.previewLayer.frame = self.m_myVideoView.bounds
            self.m_myVideoView.layer.insertSublayer((self.cameraCapture?.previewLayer)!, at: 0)
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.adjustMyVideoView()
        
        InterfaceManager.makeRadiusControl(self.m_btnEndCall, cornerRadius:self.m_btnEndCall.bounds.size.width * 0.5, withColor: UIColor.white, borderSize: 1.0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func actionSwitchCamera(_ sender: AnyObject) {
        let position: AVCaptureDevicePosition = (self.cameraCapture?.position)!
        let newPosition: AVCaptureDevicePosition = position == .back ? .front : .back
        
        if ((self.cameraCapture?.hasCamera(for: newPosition)) != nil) {
            let animation: CAAnimation = CAAnimation()
            animation.duration = 0.5
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

            self.m_myVideoView.layer.add(animation, forKey: nil)
            self.cameraCapture?.position = newPosition
        }
    }
  
    func endCallProcess () {
        
        TheVideoCallManager.endCall()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func actionEndCall(_ sender: AnyObject) {
        self.endCallProcess()
    }

    @IBAction func actionMuteSound(_ sender: AnyObject) {
        TheVideoCallManager.muteSound()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // =========================================================================
    
}
