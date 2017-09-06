//
//  VideoCallManager.swift
//  VideoChat
//
//  Created by Admin on 25/02/16.
//  Copyright © 2016 RonnieAlex. All rights reserved.
//

import UIKit
import Foundation
// import SwiftyJSON
import AVFoundation
import AssetsLibrary

protocol VideoCallManagerDelegate {
    func callErrors(_ description: String)
    func acceptedByUser ()
}

let TheVideoCallManager = VideoCallManager.sharedInstance

let kQBAnswerTimeInterval:TimeInterval = 60
let kQBRTCDisconnectTimeInterval:TimeInterval = 30
let kQBDialingTimeInterval:TimeInterval = 5

class VideoCallManager: NSObject, QBChatDelegate, QBRTCClientDelegate, AVCaptureFileOutputRecordingDelegate {
    static let sharedInstance = VideoCallManager()
    
    var otherUser: User?
    
    var recorder: AVAudioRecorder!
    var bRecording: Bool = false
    
    var delegate: VideoCallManagerDelegate? = nil
    
    var presenceTimer: QBRTCTimer? = nil
    var currentSession: QBRTCSession? = nil
    
    var opponentUserID: NSNumber? = nil
    var bIncomingCall: Bool? = false
    
    var timeDuration: TimeInterval?
    var callTimer: Timer? = nil
    var beepTimer: Timer? = nil
    
    var bAudioInCall = true
    
    var currentVideoCallViewCon: VideoCallViewController? = nil
    
    override init() {
        super.init()
    }
    
    func initProcess () {
        QBRTCConfig.setAnswerTimeInterval(kQBAnswerTimeInterval)
        QBRTCConfig.setDialingTimeInterval(kQBDialingTimeInterval)
        
        QBRTCClient.initializeRTC()
        
        let password = "baccb97ba2d92d71e26eb9886da5f1e0"
        let username = "quickblox"
        
        let urls = [
            "stun:turn.quickblox.com",
            "turn:turn.quickblox.com:3478?transport=udp",
            "turn:turn.quickblox.com:3478?transport=tcp"
        ]
        
        let server = QBRTCICEServer.init(urls: urls, username: username, password: password)
        QBRTCConfig.setICEServers([server!])
        QBRTCConfig.setMediaStreamConfiguration(QBRTCMediaStreamConfiguration.default())
        QBRTCConfig.setStatsReportTimeInterval(1.0)
        
        QBRTCClient.instance().add(self)
    }
    
    func applyConfiguration () {
        
//        let password = "baccb97ba2d92d71e26eb9886da5f1e0"
//        let username = "quickblox"
//        
//        let urls = [
//            "stun:turn.quickblox.com",
//            "turn:turn.quickblox.com:3478?transport=udp",
//            "turn:turn.quickblox.com:3478?transport=tcp"
//        ]
//        
//        let server = QBRTCICEServer.init(urls: urls, username: username, password: password)
//        QBRTCConfig.setICEServers([server!])
//        QBRTCConfig.setMediaStreamConfiguration(QBRTCMediaStreamConfiguration.default())
//        QBRTCConfig.setStatsReportTimeInterval(1.0)
//        
//        QBRTCClient.instance().add(self)
//        QBRTCAudioSession.instance().addDelegate(self)
    }
    
    func chatLoginWithUser(_ user: QBUUser, completionError:@escaping ((_ bSuccess:Bool, _ error: NSError?) -> Void)) -> Void {
        
        QBChat.instance.addDelegate(self)
        
        if QBChat.instance.isConnected {
            completionError(false, nil)
            return
        }
        
        QBChat.instance.connect(with: user, completion: { (error) -> Void in
            self.applyConfiguration()
            
            if error == nil {
                
                completionError(true, nil)
            } else {
                completionError(false, error as NSError?)
            }
        })
    }

    func chatLogout () {
        if self.presenceTimer != nil {
            self.presenceTimer?.invalidate()
            self.presenceTimer = nil
        }
        
        if QBChat.instance.isConnected {
            QBChat.instance.disconnect(completionBlock: { (error) -> Void in
                QBRTCClient.instance().remove(self)
            })
        }
    }
    
    //call process
    func callWithConferenceType(_ conferenceType: QBRTCConferenceType, opponentID: NSNumber) -> Bool? {
        let session: QBRTCSession? = QBRTCClient.instance().createNewSession(withOpponents: [opponentID], with: conferenceType)
        
        if let session = session {
            self.opponentUserID = opponentID
            self.currentSession = session
            
            bAudioInCall = true
            
            return true
        }
        
        return false
    }
    
    func muteSound() {
        bAudioInCall = !bAudioInCall
        self.currentSession?.localMediaStream.audioTrack.isEnabled = bAudioInCall
    }
    
    func stopCallingRingToneSound() {
        if beepTimer != nil {
            beepTimer?.invalidate()
            beepTimer = nil
        }
        
        QMSoundManager.instance().stopAllSounds()
    }
    
    func declineCall(_ session: QBRTCSession!) {
        if beepTimer != nil {
            beepTimer?.invalidate()
            beepTimer = nil
        }
        
        self.bIncomingCall = false

        QMSoundManager.instance().stopAllSounds()
        QMSoundManager.playEndOfCallSound();
        
        if session != nil {
            session.rejectCall(["hangup":"hang up"])
        }
    }
    
    func rejectCall(_ session: QBRTCSession!) {
        if beepTimer != nil {
            beepTimer?.invalidate()
            beepTimer = nil
        }

        self.bIncomingCall = false

        QMSoundManager.instance().stopAllSounds()
        QMSoundManager.playEndOfCallSound();
        
        if session != nil {
            session.rejectCall(["reject":"busy"])
        }
    }
    
    func endCall() {
        if beepTimer != nil {
            beepTimer?.invalidate()
            beepTimer = nil
        }

        self.bIncomingCall = false
        
        QMSoundManager.instance().stopAllSounds()
        QMSoundManager.playEndOfCallSound();
        
        if self.currentSession != nil {
            self.currentSession?.hangUp(["end":"end of call"])
        }
    }
    
    func startCall() {
        if beepTimer != nil {
            beepTimer?.invalidate()
            beepTimer = nil
        }

        self.bIncomingCall = false

        self.beepTimer = Timer.scheduledTimer(timeInterval: QBRTCConfig.dialingTimeInterval(), target: self, selector: #selector(VideoCallManager.playCallingSound), userInfo: nil, repeats: true)
        
        self.playCallingSound()
        
        if self.currentSession != nil {
            print(TheGlobalPoolManager.currentUser?.chatID)
            self.currentSession?.startCall(["startCall":String(format: "%d", (TheGlobalPoolManager.currentUser?.chatID)!)])
        }
    }
    
    func acceptCall() {
        if beepTimer != nil {
            beepTimer?.invalidate()
            beepTimer = nil
        }

        QMSoundManager.instance().stopAllSounds()
        if self.currentSession != nil {
            self.currentSession?.acceptCall(["startCall":String(format: "%d", (TheGlobalPoolManager.currentUser?.chatID)!)])
        }
    }
    
    func incomingCall() {
        if beepTimer != nil {
            beepTimer?.invalidate()
            beepTimer = nil
        }
        
        self.beepTimer = Timer.scheduledTimer(timeInterval: QBRTCConfig.dialingTimeInterval(), target: self, selector: #selector(VideoCallManager.playRingToneSound), userInfo: nil, repeats: true)
    }
    
    func playCallingSound() {
        QMSoundManager.playCallingSound()
    }
    
    func playRingToneSound() {
        QMSoundManager.playRingtoneSound()
    }
    
    //QBChatDelegate
    func chatDidNotConnectWithError(_ error: Error?) {
    }
    
    func chatDidAccidentallyDisconnect() {
    }
    
    func chatDidFail(withStreamError error: Error?) {
    }
    
    func chatDidConnect() {
        QBChat.instance.sendPresence(withStatus: "Connected 101")
        
        self.presenceTimer = QBRTCTimer(timeInterval: kChatPresenceTimeInterval, repeat: true, queue: DispatchQueue.main, completion:{
                QBChat.instance.sendPresence(withStatus: "Connected 102")
            },
            expiration: {
                if QBChat.instance.isConnected {
                    QBChat.instance.disconnect(completionBlock: { (error) -> Void in
                    })
                }
                
                if self.presenceTimer != nil {
                    self.presenceTimer?.invalidate()
                    self.presenceTimer = nil
                }
        })
    }
    
    func chatDidReconnect() {
    }
    
    //QBRTCClientDelegate
    
    func didReceiveNewSession(_ session: QBRTCSession, userInfo: [String : String]? = nil) {
        print("START: Received new session for video call")
        if session == nil {
            return
        }
        print("Incoming session not nil")
        
        if self.currentSession != nil {
            session.rejectCall(["reject":"busy"])
            return
        }
        print("No current ongoing session")
        
        if self.currentSession == session {
            return
        }
        
        self.currentSession = session
        
        let someString = userInfo?["startCall"]!
        if let myInteger = UInt(someString!) {
            let myNumber = NSNumber(value:myInteger)
            
            
            //        let myInteger = Int((userInfo?["startCall"])!)
            //        let otherUserQuickbloxID = myInteger
            //        let params: [String: Any] = ["qb_id": otherUserQuickbloxID]
            
            print("Got other user's qb_id: \(myNumber)")
            //        WebServiceAPI.postDataWithURL(Constants.APINames.GetStudentInfo,
            //                                      withoutHeader: false,
            //                                      params: params,
            //                                      completionBlock:
            //            {(request, response, data) -> Void in
            //
            //                print("Received user info from server while trying to accept call")
            //                if let responseFromServer = JSON(data).dictionary,
            //                    let userJSON = responseFromServer["userInfo"]?.dictionary {
            //
            //                    print("Parsed response into JSON")
            //                    do {
            //                        let otherUser = try User(fromJSON: userJSON)
            
            self.opponentUserID = myNumber
            
            print("Parsed other user successfully with opponentUserID = \(self.opponentUserID)")
            
            TheGlobalPoolManager.bCallerUser = false
            
            //present incoming call view controller
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let viewCon: IncomingCallViewController = storyboard.instantiateViewController(withIdentifier: "incomingcallview") as! IncomingCallViewController
            viewCon.strOpponentUserName = "test user"
            //                        viewCon.strOpponentUserName = otherUser.username
            //                        viewCon.strOpponentUserProfileUrl = otherUser.profilePicUrl
            
            self.bIncomingCall = true
            
            UIApplication.topViewController()?.present(viewCon, animated: true, completion: nil)
            
            //                    } catch {
            //                        print("ERROR: Could not load opponent user: \(error)")
            //                    }
            //                }
            //
            //            }, errBlock: {(errorString) -> Void in
            //        })
        }

    }
    
    func sessionDidClose(_ session: QBRTCSession) {
        if session == self.currentSession {
            let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.currentSession = nil
            }
        }
    }
    
    func session(_ session: QBRTCBaseSession, updatedStatsReport report: QBRTCStatsReport, forUserID userID: NSNumber) {
        
    }
    
    func session(_ session: QBRTCSession, userDidNotRespond userID: NSNumber) {
        if session == self.currentSession {
            self.currentSession?.connectionState(forUser: userID)
            if  self.delegate != nil {
                self.delegate?.callErrors("User does not respond!")
            }
        }
    }
    
    func session(_ session: QBRTCSession!, initializedLocalMediaStream mediaStream: QBRTCMediaStream!) {
        if self.currentSession?.conferenceType == .video {
            session.localMediaStream.videoTrack.videoCapture = self.currentVideoCallViewCon?.cameraCapture
        }
    }

    func session(_ session: QBRTCSession, hungUpByUser userID: NSNumber, userInfo: [String : String]? = nil) {
        if session == self.currentSession {
            self.currentSession?.connectionState(forUser: userID)
            if (self.currentVideoCallViewCon != nil) {
                self.currentVideoCallViewCon?.endCallProcess()
            }
        }
    }
    
    func session(_ session: QBRTCSession, acceptedByUser userID: NSNumber, userInfo: [String : String]? = nil) {
        if session == self.currentSession {
            self.opponentUserID = userID;
            self.currentSession?.connectionState(forUser: userID)
            
            if  self.delegate != nil {
                self.stopCallingRingToneSound()
                self.delegate?.acceptedByUser()
            }
        }
    }
  
    func session(_ session: QBRTCSession, rejectedByUser userID: NSNumber, userInfo: [String : String]? = nil) {
        if session == self.currentSession {
            self.currentSession?.connectionState(forUser: userID)
            
            if  self.delegate != nil {
                self.delegate?.callErrors("Rejected your call!")
            }
        }
    }
    
    func session(_ session: QBRTCBaseSession, receivedRemoteVideoTrack videoTrack: QBRTCVideoTrack, fromUser userID: NSNumber) {
        if session == self.currentSession {
            self.currentVideoCallViewCon?.m_opponentVideoView.setVideoTrack(videoTrack)
        }
    }
  
    func session(_ session: QBRTCBaseSession, receivedRemoteAudioTrack audioTrack: QBRTCAudioTrack, fromUser userID: NSNumber) {
        audioTrack.isEnabled = true
    }
    
    func session(_ session: QBRTCBaseSession, startedConnectingToUser userID: NSNumber) {
        if session == self.currentSession {
            self.currentSession?.connectionState(forUser: userID)
            
            if self.currentVideoCallViewCon != nil {
                self.currentVideoCallViewCon?.connectingActivity.isHidden = true
            }
        }
    }
    
    func session(_ session: QBRTCBaseSession, connectedToUser userID: NSNumber) {
        if session == self.currentSession {
            self.currentSession?.connectionState(forUser: userID)
            
            if self.currentVideoCallViewCon != nil {
                self.currentVideoCallViewCon?.connectingActivity.isHidden = true
            }
        }
    }
    
    func session(_ session: QBRTCBaseSession, connectionClosedForUser userID: NSNumber) {
        print("Session connection closed for user \(userID) <- Is that me or the other user??")
        if session == self.currentSession {
            self.currentSession?.connectionState(forUser: userID)
            //            self.currentVideoCallViewCon?.m_opponentVideoView.setVideoTrack(nil)
            
            if beepTimer != nil {
                beepTimer?.invalidate()
                beepTimer = nil
            }
            
            if  self.delegate != nil {
                self.delegate?.callErrors("Call is ended!")
            }
        }
    }
    
   func session(_ session: QBRTCBaseSession, disconnectedFromUser userID: NSNumber) {
        if session == self.currentSession {
            self.currentSession?.connectionState(forUser: userID)
            
            if beepTimer != nil {
                beepTimer?.invalidate()
                beepTimer = nil
            }
            
            if  self.delegate != nil {
                self.delegate?.callErrors("Disconnected!")
            }
        }
    }
    
   func session(_ session: QBRTCSession!, disconnectedByTimeoutFromUser userID: NSNumber!) {
        if session == self.currentSession {
            self.currentSession?.connectionState(forUser: userID)
            
            if beepTimer != nil {
                beepTimer?.invalidate()
                beepTimer = nil
            }
            
            if  self.delegate != nil {
                self.delegate?.callErrors("Timeout error!")
            }
        }
    }
    
    func session(_ session: QBRTCBaseSession, connectionFailedForUser userID: NSNumber) {
        if session == self.currentSession {
            self.currentSession?.connectionState(forUser: userID)
            
            if beepTimer != nil {
                beepTimer?.invalidate()
                beepTimer = nil
            }
            
            if  self.delegate != nil {
                self.delegate?.callErrors("Connection is failed!")
            }
        }
    }
    
    //video save
    // MARK: File Output Delegate
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        LoadingOverlay.shared.hideOverlayView()
        
        if(error != nil){
            print(error)
        }
        ALAssetsLibrary().writeVideoAtPath(toSavedPhotosAlbum: outputFileURL) { (url, error) in
            
            if error != nil{
                print(error)
                
            }
            
            do {
                try FileManager.default.removeItem(at: outputFileURL)
            } catch _ {
            }
        }
        
    }

    // MARK: - AVAudioRecorder Delegate Methods
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Finished Recording")
        
    }
    

 }
