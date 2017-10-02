//
//  SignupViewController.swift
//  CLF-Chat
//
//  Created by Admin on 11/08/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

protocol AddGroupUserDelegate {
    func getGroupUser(_ selUser : String, userIDs : [NSNumber])
}

class NewMessageViewController: UIViewController, AddGroupUserDelegate, UIActionSheetDelegate, QMChatServiceDelegate, QMChatConnectionDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var txtUser: UITextField!
    @IBOutlet weak var txtSubject: UITextField!
    @IBOutlet weak var txtMessage: UITextView!
    
    let imagePicker = UIImagePickerController()
    var selectedImage: UIImage? = nil
    
    var dialog: QBChatDialog?
//    var selMembers : [GroupMember] = []
    var userIDs:[NSNumber] = []
    
    @IBOutlet weak var m_subjectView: UIView!
    @IBOutlet weak var m_messageViewConstraint: NSLayoutConstraint!
    var isGroup : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.imagePicker.delegate = self
        
        txtSubject.delegate = self
        txtMessage.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ServicesManager.instance().chatService.addDelegate(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismissKeyboard()
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        txtSubject.resignFirstResponder()
        txtMessage.resignFirstResponder()
    }
    
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionAddUser(_ sender: Any) {
        let viewCon = self.storyboard?.instantiateViewController(withIdentifier: "AddUserViewController") as! AddUserViewController!
        viewCon?.selUsers = self.txtUser.text!
        viewCon?.userIDs = self.userIDs
        viewCon?.delegate = self
        self.navigationController?.pushViewController(viewCon!, animated: true)
    }
    
    @IBAction func actionAttach(_ sender: Any) {
        
        let alertView = UIAlertController(title: "Choose Option", message: nil, preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "Camera", style: .default, handler: { (alert) in
            self.takePhoto()
        })
        alertView.addAction(action)
        
        let action1 = UIAlertAction(title: "Photo Library", style: .default, handler: { (alert) in
            self.choosePhotoFromLibrary()
        })
        alertView.addAction(action1)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (alert) in
            alertView.dismiss(animated: true, completion: nil)
        })
        alertView.addAction(cancel)
        
        self.present(alertView, animated: true, completion: nil)
    }
    
    @IBAction func actionSend(_ sender: Any) {
        if validateInput() {
            var users: [QBUUser] = []
            
            for elem in self.userIDs {
                
                var user:QBUUser = QBUUser()
                
                user = TheGlobalPoolManager.getQUser(chatID: UInt(elem))
                users.append(user)
            }
            
            let completion = {[weak self] (response: QBResponse?, createdDialog: QBChatDialog?) -> Void in
                
                if createdDialog != nil {
                    
                    print(createdDialog)
                    self?.openNewDialog(dialog: createdDialog)
                }
                
                guard let unwrappedResponse = response else {
                    print("Error empty response")
                    return
                }
                
                if let error = unwrappedResponse.error {
                    print(error.error)
                    SVProgressHUD.showError(withStatus: error.error?.localizedDescription)
                }
                else {
                    SVProgressHUD.showSuccess(withStatus: "STR_DIALOG_CREATED".localized)
                }
            }
            
            if let dialog = self.dialog {
                
                if dialog.type == .group {
                    
                    SVProgressHUD.show(withStatus: "SA_STR_LOADING".localized, maskType: SVProgressHUDMaskType.clear)
                    
                    self.updateDialog(dialog: self.dialog!, newUsers:users, completion: {[weak self] (response, dialog) -> Void in
                        
                        guard response?.error == nil else {
                            SVProgressHUD.showError(withStatus: response?.error?.error?.localizedDescription)
                            return
                        }
                        
                        SVProgressHUD.showSuccess(withStatus: "STR_DIALOG_CREATED".localized)
                        
                        self?.openNewDialog(dialog: dialog)
                    })
                    
                }
                else {
                    
                    guard let usersWithoutCurrentUser = ServicesManager.instance().sortedUsersWithoutCurrentUser() else {
                        print("No users found")
                        return
                    }
                    
                    guard let dialogOccupants = dialog.occupantIDs else {
                        print("Dialog has not occupants")
                        return
                    }
                    
                    let usersInDialogs = usersWithoutCurrentUser.filter({ (user) -> Bool in
                        
                        return dialogOccupants.contains(NSNumber(value: user.id))
                    })
                    
                    if usersInDialogs.count > 0 {
                        users.append(contentsOf: usersInDialogs)
                    }
                    
                    let chatName = self.nameForGroupChatWithUsers(users: users)
                    
                    self.createChat(name: chatName, users: users, completion: completion)
                }
                
            }
            else {
                
                let chatName = txtSubject.text
                
//                if users.count == 1 {
                
                    self.createChat(name: chatName, users: users, completion: completion)
                    
//                }
//                else {
//                    
//                    _ = AlertViewWithTextField(title: "SA_STR_ENTER_CHAT_NAME".localized, message: nil, showOver:self, didClickOk: { (text) -> Void in
//                        
//                        var chatName = text!.trimmingCharacters(in: CharacterSet.whitespaces)
//                        
//                        
//                        if chatName.isEmpty {
//                            chatName = self.nameForGroupChatWithUsers(users: users)
//                        }
                    
//                        self.createChat(name: chatName, users: users, completion: completion)
                
//                    }) { () -> Void in
//                        
//                    }
//                }
            }
        }
    }
    
    func openNewDialog(dialog: QBChatDialog!) {
        self.dialog = dialog
        
        let navigationArray = self.navigationController?.viewControllers
        let newStack = [] as NSMutableArray
        
        for vc in navigationArray! {
            // ChatViewController
            newStack.add(vc)
            if vc is HomeViewController {
                let chatVC = self.storyboard!.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
                chatVC.dialog = dialog
                newStack.add(chatVC)
                self.navigationController!.setViewControllers(newStack.copy() as! [UIViewController], animated: true)
                return;
            }
        }
    }
    
    func updateDialog(dialog:QBChatDialog, newUsers users:[QBUUser], completion: ((_ response: QBResponse?, _ dialog: QBChatDialog?) -> Void)?) {
        
        let usersIDs = users.map{ NSNumber(value: $0.id) }
        
        // Updates dialog with new occupants.
        ServicesManager.instance().chatService.joinOccupants(withIDs: usersIDs, to: dialog) { [weak self] (response, dialog) -> Void in
            
            guard response.error == nil else {
                SVProgressHUD.showError(withStatus: response.error?.error?.localizedDescription)
                
                completion?(response, nil)
                return
            }
            
            guard let unwrappedDialog = dialog else {
                print("Received dialog is nil")
                return
            }
            guard let strongSelf = self else { return }
            let notificationText = strongSelf.updatedMessageWithUsers(users: users,isNewDialog: false)
            
            // Notifies users about new dialog with them.
            ServicesManager.instance().chatService.sendSystemMessageAboutAdding(to: unwrappedDialog, toUsersIDs: usersIDs, withText: notificationText, completion: { (error) in
                
                ServicesManager.instance().chatService.sendNotificationMessageAboutAddingOccupants(usersIDs, to: unwrappedDialog, withNotificationText: notificationText)
                
                print(unwrappedDialog)
                
                completion?(response, unwrappedDialog)
            })
        }
    }
    
    func nameForGroupChatWithUsers(users:[QBUUser]) -> String {
        
        let chatName = ServicesManager.instance().currentUser.fullName! + "_" + users.map({ $0.login ?? $0.email! }).joined(separator: ", ").replacingOccurrences(of: "@", with: "", options: String.CompareOptions.literal, range: nil)
        
        return chatName
    }
    
    func createChat(name: String?, users:[QBUUser], completion: ((_ response: QBResponse?, _ createdDialog: QBChatDialog?) -> Void)?) {
        
        SVProgressHUD.show(withStatus: "SA_STR_LOADING".localized, maskType: SVProgressHUDMaskType.clear)
        
        if users.count == 1 {
            // Creating private chat.
            ServicesManager.instance().chatService.createPrivateChatDialog(withOpponent: users.first!, completion: { (response, chatDialog) in
                
                self.dialog = chatDialog
                self.sendMessage()
                
                completion?(response, chatDialog)
            })
            
        } else {
            // Creating group chat.
            
            ServicesManager.instance().chatService.createGroupChatDialog(withName: name, photo: nil, occupants: users) { [weak self] (response, chatDialog) -> Void in
                
                
                guard response.error == nil else {
                    
                    SVProgressHUD.showError(withStatus: response.error?.error?.localizedDescription)
                    return
                }
                
                guard let unwrappedDialog = chatDialog else {
                    return
                }
                
                guard let dialogOccupants = chatDialog?.occupantIDs else {
                    print("Chat dialog has not occupants")
                    return
                }
                
                guard let strongSelf = self else { return }
                
                let notificationText = strongSelf.updatedMessageWithUsers(users: users, isNewDialog: true)
                
                ServicesManager.instance().chatService.sendSystemMessageAboutAdding(to: unwrappedDialog, toUsersIDs: dialogOccupants, withText:notificationText, completion: { (error) -> Void in
                    
                    ServicesManager.instance().chatService.sendNotificationMessageAboutAddingOccupants(dialogOccupants, to: unwrappedDialog, withNotificationText: notificationText)
                    
                    strongSelf.dialog = chatDialog
                    strongSelf.sendMessage()
                    
                    completion?(response, unwrappedDialog)
                })
            }
        }
    }

    func updatedMessageWithUsers(users: [QBUUser],isNewDialog:Bool) -> String {
        
        let dialogMessage = isNewDialog ? "SA_STR_CREATE_NEW".localized : "SA_STR_ADDED".localized
        
        var message: String = (TheGlobalPoolManager.currentUser?.fname)! + " " + (TheGlobalPoolManager.currentUser?.lname)! + dialogMessage + " "
        for user: QBUUser in users {
            message = "\(message)\(user.fullName!),"
        }
        message.remove(at: message.index(before: message.endIndex))
        return message
    }
    
    func takePhoto() {
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            self.imagePicker.allowsEditing = true
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: nil)
        }
    }
    
    
    func choosePhotoFromLibrary() {
        self.imagePicker.allowsEditing = true
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    func validateInput() -> Bool {
        
        if txtUser.text?.length == 0 {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "Please select users")
            return false
        }
        
        if isGroup {
            if txtSubject.text?.length == 0 {
                InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "Please enter subject")
                return false
            }
        }

        if txtMessage.text?.length == 0 {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "Please enter message")
            return false
        }
        
        return true
    }
    
    func getGroupUser(_ selUser : String, userIDs : [NSNumber]) {
        print(selUser)
        
        txtUser.text = selUser
        self.userIDs = userIDs
        
        if userIDs.count > 1 {
            m_messageViewConstraint.constant = 15
            m_subjectView.isHidden = false
            isGroup = true
        } else {
            m_subjectView.isHidden = true
            m_messageViewConstraint.constant = -45
            isGroup = false
        }
        
        self.view.layoutIfNeeded()
    }
    
    // MARK: - QMChatServiceDelegate
    
    func chatService(_ chatService: QMChatService, didUpdateChatDialogInMemoryStorage chatDialog: QBChatDialog) {
        
        if (chatDialog.id == self.dialog?.id) {
            self.dialog = chatDialog
        }
    }
    
    //MARK: - TextView delegate
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
        if textView == self.txtMessage {
            if self.txtMessage.text == "Message" {
                self.txtMessage.text = ""
            }
            self.txtMessage.textColor = UIColor.black
        }
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if self.txtMessage.text == "" {
            self.txtMessage.text = "Message"
            self.txtMessage.textColor = UIColor.lightGray
        }
    }
    
    func queueManager() -> QMDeferredQueueManager {
        return ServicesManager.instance().chatService.deferredQueueManager
    }
    
    //MARK : send message
    func sendMessage() {
        
        let message = QBChatMessage()
        message.senderID = (TheGlobalPoolManager.currentUser?.chatID)!
        message.dateSent = Date()
        
        if self.selectedImage != nil {

            message.dialogID = (self.dialog?.id!)!
            ServicesManager.instance().chatService.sendAttachmentMessage(message, to: self.dialog!, withAttachmentImage: self.selectedImage!, completion: {
                [weak self] (error: Error?) -> Void in
                
                guard error != nil else { return }
                
                // perform local attachment message deleting if error
                ServicesManager.instance().chatService.deleteMessageLocally(message)
            })
            
        } else {
            
            if !self.queueManager().shouldSendMessagesInDialog(withID: (self.dialog?.id!)!) {
                return
            }
            
            message.text = self.txtMessage.text
            message.deliveredIDs = [(NSNumber(value: (TheGlobalPoolManager.currentUser?.chatID)!))]
            message.readIDs = [(NSNumber(value: (TheGlobalPoolManager.currentUser?.chatID)!))]
            message.markable = true
            
            // Sending message.
            ServicesManager.instance().chatService.send(message, toDialogID: (self.dialog?.id!)!, saveToHistory: true, saveToStorage: true) { (error) ->
                Void in
                
                if error != nil {
                    
                    QMMessageNotificationManager.showNotification(withTitle: "SA_STR_ERROR".localized, subtitle: error?.localizedDescription, type: QMMessageNotificationType.warning)
                }
            }
        }
    }
}

extension NewMessageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - UIImagePicker Delegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.selectedImage = image
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.selectedImage = image
        } else {
            print("ERROR: Failed to finish picking image")
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
