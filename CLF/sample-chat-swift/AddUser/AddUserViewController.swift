//
//  SignupViewController.swift
//  CLF-Chat
//
//  Created by Admin on 11/08/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class AddUserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, QMChatServiceDelegate, QMChatConnectionDelegate {
    
    var bloadedView : Bool = false
    var searchActive : Int = 0
    
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var myGroupView: UIView!
    @IBOutlet weak var myGroupTableView: UITableView!
    
    
    @IBOutlet weak var contactsView: UIView!
    @IBOutlet weak var contactsTableView: UITableView!
    @IBOutlet weak var searchBarView: UISearchBar!
    
    @IBOutlet weak var userlist: UILabel!
    
    var groupMember:[GroupMember] = []
    
    var section_names = [String]()
    var section_allContact : [[GroupMember]] = []
    
    var filter_section_names = [String]()
    var filter_section_allContact : [[GroupMember]] = []
    
    var selUsers : String = ""
    
    var userIDs:[NSNumber] = []
    
    var delegate : AddGroupUserDelegate? = nil
    
    var selMember:[GroupMember] = []
    
    var dialog: QBChatDialog!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (bloadedView) {
            return
        }
        
        bloadedView = true
        
        contactsView.isHidden = true
        searchBarView.delegate = self
        
        self.initConstraint()
        makeTableViewSetup(0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        
        ServicesManager.instance().chatService.addDelegate(self)
        
        self.getGroupMember()
        
        self.myGroupTableView.reloadData()
        self.contactsTableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        userlist.text = selUsers
    }
    
    func initConstraint() {
        self.view.layoutIfNeeded()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismissKeyboard()
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.view.endEditing(true)
    }
    
    func makeTableViewSetup(_ fBottomInset: CGFloat) {
        
        self.myGroupTableView.delegate = self
        self.myGroupTableView.dataSource = self
        
        self.myGroupTableView.tableFooterView = UIView()
        self.myGroupTableView.backgroundColor = UIColor.clear
        
        let edgeInsets = UIEdgeInsetsMake(0.0, 0.0, fBottomInset, 0.0)
        self.myGroupTableView.contentInset = edgeInsets
        self.myGroupTableView.scrollIndicatorInsets = edgeInsets
        
        self.myGroupTableView.setNeedsLayout()
        self.myGroupTableView.layoutIfNeeded()
        
        self.contactsTableView.delegate = self
        self.contactsTableView.dataSource = self
        
        self.contactsTableView.tableFooterView = UIView()
        self.contactsTableView.backgroundColor = UIColor.clear
        
        self.contactsTableView.contentInset = edgeInsets
        self.contactsTableView.scrollIndicatorInsets = edgeInsets
        
        self.contactsTableView.setNeedsLayout()
        self.contactsTableView.layoutIfNeeded()
    }
    
    func getGroupMember() {
        
        let user = TheGlobalPoolManager.currentUser
        let token = TheGlobalPoolManager.accessToken
        
        let getGroupMemberAPI_link : String = String.init(format: Constants.APINames.GroupMember, (user?.username)!, TheGlobalPoolManager.placeID, TheGlobalPoolManager.conciergeID)
        
        LoadingOverlay.shared.showOverlay(self.view)
        
        WebServiceAPI.getDataWithURL(getGroupMemberAPI_link, token: token, params: nil, withoutHeader: false, cacheKey: nil, completionBlock:
            {(request, response, json, false)->Void in
                
                LoadingOverlay.shared.hideOverlayView()
                
                if let responseJSON = json.array {
                    
                    let first_dic = responseJSON[0].dictionary
                    let placename = first_dic?["placeName"]?.string
                    
                    if let people_arr = first_dic?["people"]?.array {
                        
                        self.groupMember.removeAll()
                        
                        for elem in people_arr {
                            do {
                                
                                let obj = try GroupMember.init(fromJSON: elem.dictionary!, placename: placename!)
                                self.groupMember.append(obj)
                            } catch {
                                print("ERROR: failed to initialize GroupMember from JSON: \(error)")
                            }
                        }
                    
                        self.myGroupTableView.reloadData()
                    }
                }
                
        }, errBlock: {(errorString) -> Void in
            TheInterfaceManager.showLocalValidationError(self, errorMessage: errorString)
            LoadingOverlay.shared.hideOverlayView()
        })
    }
    
    func getAllContacts() {
        
        let user = TheGlobalPoolManager.currentUser
        let token = TheGlobalPoolManager.accessToken
        
        let getAllContactsAPI_link : String = String.init(format: Constants.APINames.AllContacts, (user?.username)!, TheGlobalPoolManager.placeID, TheGlobalPoolManager.conciergeID)
        
        LoadingOverlay.shared.showOverlay(self.view)
        
        WebServiceAPI.getDataWithURL(getAllContactsAPI_link, token: token, params: nil, withoutHeader: false, cacheKey: nil, completionBlock:
            {(request, response, json, false)->Void in
                
                LoadingOverlay.shared.hideOverlayView()
                
                if let responseJSON = json.array {
                    
                    for setion in responseJSON {
                        do {
                            let placename = setion["placeName"].string
                            self.section_names.append(placename!)       //get section names
                            
                            if let people_arr = setion["people"].array {   //get users for place
                                
                                var section_contacts = [GroupMember]()
                                
                                for elem in people_arr {
                                    do {
                                        
                                        let obj = try GroupMember.init(fromJSON: elem.dictionary!, placename: placename!)
                                        section_contacts.append(obj)
                                        
                                    } catch {
                                        print("ERROR: failed to initialize GroupMember from JSON: \(error)")
                                    }
                                }
                                
                                self.section_allContact.append(section_contacts)
                            }
                            
                        } catch {
                            print("ERROR: failed to initialize AllContacts from JSON: \(error)")
                        }
                    }
                    
                    self.contactsTableView.reloadData()
                }
                
        }, errBlock: {(errorString) -> Void in
            TheInterfaceManager.showLocalValidationError(self, errorMessage: errorString)
            LoadingOverlay.shared.hideOverlayView()
        })
    }
    
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionAddUser(_ sender: Any) {
        if userlist.text?.length == 0 {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "Please select users")
            return
        }
        
        if dialog == nil {  //Add users for New Chat
            
            self.navigationController?.popViewController(animated: true)
            
            if self.delegate != nil {
                self.delegate!.getGroupUser(selUsers, selMember: selMember, userIDs: userIDs)
            }
        } else {    //Add Participant for existing Chat
            self.addParticipant()
        }
    }
    
    @IBAction func actionSelTab(_ sender: UIButton) {
        if sender.tag == 10 {
            myGroupView.isHidden = false
            contactsView.isHidden = true
            
            UIView.animate(withDuration: 0.3, animations: {
                self.leftConstraint.constant = 0
                self.view.layoutIfNeeded()
            }, completion: { (bFinished: Bool) -> Void in
                if (bFinished) {
                    
                }
            })
            
            self.getGroupMember()
            
        } else {
            myGroupView.isHidden = true
            contactsView.isHidden = false
            
            UIView.animate(withDuration: 0.3, animations: {
                self.leftConstraint.constant = UIScreen.main.bounds.size.width / 3.0
                self.view.layoutIfNeeded()
            }, completion: { (bFinished: Bool) -> Void in
                if (bFinished) {
                    
                }
            })
            
            self.getAllContacts()
        }
    }
    
    func actionAdd(_ sender: UIButton) {
        print(sender.tag)
        
        let group = self.section_allContact[sender.tag]
        
        print(group.count)
        
        for elem in group {
            
            let myInteger = Int((elem.chatID)!)
            let chatID = NSNumber(value:myInteger!)
            
            let username = String.init(format: "%@ %@", elem.fname!, elem.lname!)
            
            if !(userIDs.contains(chatID)) {
                selMember.append(elem)
                userIDs.append(chatID)
                selUsers = selUsers + username + ", "
                
            } else {
                if let index = userIDs.index(of:chatID) {
                    userIDs.remove(at: index)
                    selMember.remove(at: index)
                    selUsers = selUsers.replacingOccurrences(of: username + ", ", with: "", options: .literal, range: nil)
                    
                }
            }
            
            userlist.text = selUsers
        }
        
        self.contactsTableView.reloadData()
    }
    
    // MARK: - Searchbar delegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = 0;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = 0;
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = 0;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = 0;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText == "" {
            searchActive = 0;
        } else {
            filter_section_names = section_names.filter({ (text) -> Bool in
                let tmp: NSString = text as NSString
                let range = tmp.range(of: searchText, options: .caseInsensitive)
                return range.location != NSNotFound
            })
            
            searchActive = 1;
            
            filter_section_allContact = []
            
            for item in filter_section_names {
                let indexOfA = section_names.index(of: item)
                
                filter_section_allContact.append(section_allContact[indexOfA!])
            }
        }
    
        
        self.contactsTableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if tableView == contactsTableView {
            if searchActive != 0 {
                return filter_section_names[section]
            }
            return section_names[section]
        }
        
        return ""
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if tableView == contactsTableView {
        
            let frame = tableView.frame

            let button = UIButton(frame: CGRect(x: frame.size.width - 50, y: 15, width: 20, height: 20))  // create button
            button.tag = section
            // the button is image - set image
            button.setImage(UIImage(named: "ic_add"), for: UIControlState.normal)  // assumes there is an image named "remove_button"
            button.addTarget(self, action: #selector(AddUserViewController.actionAdd(_:)), for: .touchUpInside)  // add selector called by clicking on the button
            
            let label = UILabel(frame: CGRect(x: 16, y: 14.5, width: 250, height: 21))
            label.text = section_names[section]
            
            let headerView = UIView(frame: CGRect(x:0, y:0, width:frame.size.width, height:50))  // create custom view
            
//            headerView.backgroundColor = UIColor.init(red: 200, green: 200, blue: 206)
            
            headerView.addSubview(label)
            headerView.addSubview(button)   // add the button to the view
            
            
            return headerView
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == contactsTableView {
            return 50.0
        }
        
        return 0.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if tableView == contactsTableView {
            if searchActive != 0 {
                return filter_section_names.count
            }

            return section_names.count
        }
        
        return 1
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 72.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == myGroupTableView {
            return self.groupMember.count
        } else if tableView == contactsTableView {
            if searchActive != 0 {
                return filter_section_allContact[section].count
            }
            return section_allContact[section].count
        }

        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellID.UserCell, for: indexPath as IndexPath) as! UserCell
        
        if tableView == myGroupTableView {
        
            let member = self.groupMember[indexPath.row]
            
            cell.m_userName.text = String.init(format: "%@ %@", member.fname!, member.lname!)
            cell.m_placename.text = member.placename
            
            if let myInteger = Int((member.chatID)!) {
                let chatID = NSNumber(value:myInteger)
                
                if userIDs.contains(chatID) {
                    cell.backgroundColor = UIColor.init(red: 189, green: 255, blue: 242)
                } else {
                    cell.backgroundColor = UIColor.clear
                }
            }
            
        } else if tableView == contactsTableView {
            
            var member : GroupMember? = nil
            
            if searchActive != 0 {
                member = self.filter_section_allContact[indexPath.section][indexPath.row]
            } else {
                member = self.section_allContact[indexPath.section][indexPath.row]
            }
            
            cell.m_userName.text = String.init(format: "%@ %@", (member?.fname!)!, (member?.lname!)!)
            cell.m_placename.text = String.init(format: "(%@)", (member?.placename!)!)
            
            if let myInteger = Int((member?.chatID)!) {
                let chatID = NSNumber(value:myInteger)
                
                if userIDs.contains(chatID) {
                    cell.backgroundColor = UIColor.init(red: 189, green: 255, blue: 242)
                } else {
                    cell.backgroundColor = UIColor.clear
                }
            } else {
                cell.backgroundColor = UIColor.clear
            }
            
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var member:GroupMember? = nil
        
        if tableView == myGroupTableView {
            member = self.groupMember[indexPath.row]
            
        } else {
            member = self.section_allContact[indexPath.section][indexPath.row]
            
        }
        
        if let myInteger = Int((member?.chatID)!) {
            let chatID = NSNumber(value:myInteger)
            let username = String.init(format: "%@ %@", (member?.fname!)!, (member?.lname!)!)
            
            if userIDs.contains(chatID) {
                if let index = userIDs.index(of:chatID) {
                    userIDs.remove(at: index)
                    selMember.remove(at: index)
                    selUsers = selUsers.replacingOccurrences(of: username + ", ", with: "", options: .literal, range: nil)
                }
                
            } else {
                selMember.append(member!)
                userIDs.append(chatID)
                selUsers = selUsers + username + ", "
            }
        } else {
            InterfaceManager.sharedInstance.showLocalValidationError(self, errorMessage: "This user haven't Chat ID")
        }

        userlist.text = selUsers

        tableView.reloadData()
    }
    
    func addParticipant() {
        var users: [QBUUser] = []
        
        for elem in self.selMember {
            
            let user:QBUUser = QBUUser()
            user.id = UInt(elem.chatID!)!
            user.email = elem.email
            user.password = "4GM@k3$G*S"
            user.fullName = String.init(format: "%@ %@", elem.fname!, elem.lname!)
            
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
            
            if users.count == 1 {
                
                self.createChat(name: nil, users: users, completion: completion)
                
            }
            else {
                
                _ = AlertViewWithTextField(title: "SA_STR_ENTER_CHAT_NAME".localized, message: nil, showOver:self, didClickOk: { (text) -> Void in
                    
                    var chatName = text!.trimmingCharacters(in: CharacterSet.whitespaces)
                    
                    
                    if chatName.isEmpty {
                        chatName = self.nameForGroupChatWithUsers(users: users)
                    }
                    
                    self.createChat(name: chatName, users: users, completion: completion)
                    
                }) { () -> Void in
                    
                }
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
    
    /**
     Creates string Login1 added login2, login3
     
     - parameter users: [QBUUser] instance
     
     - returns: String instance
     */
    func updatedMessageWithUsers(users: [QBUUser],isNewDialog:Bool) -> String {
        
        let dialogMessage = isNewDialog ? "SA_STR_CREATE_NEW".localized : "SA_STR_ADDED".localized
        
        var message: String = "\(QBSession.current.currentUser!.fullName!) " + dialogMessage + " "
        for user: QBUUser in users {
            message = "\(message)\(user.fullName!),"
        }
        message.remove(at: message.index(before: message.endIndex))
        return message
    }
    
    func nameForGroupChatWithUsers(users:[QBUUser]) -> String {
        
        let chatName = ServicesManager.instance().currentUser.login! + "_" + users.map({ $0.login ?? $0.email! }).joined(separator: ", ").replacingOccurrences(of: "@", with: "", options: String.CompareOptions.literal, range: nil)
        
        return chatName
    }
    
    func createChat(name: String?, users:[QBUUser], completion: ((_ response: QBResponse?, _ createdDialog: QBChatDialog?) -> Void)?) {
        
        SVProgressHUD.show(withStatus: "SA_STR_LOADING".localized, maskType: SVProgressHUDMaskType.clear)
        
        if users.count == 1 {
            // Creating private chat.
            ServicesManager.instance().chatService.createPrivateChatDialog(withOpponent: users.first!, completion: { (response, chatDialog) in
                
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
                    
                    completion?(response, unwrappedDialog)
                })
            }
        }
    }
    
    func openNewDialog(dialog: QBChatDialog!) {
        self.dialog = dialog
        
        let navigationArray = self.navigationController?.viewControllers
        let newStack = [] as NSMutableArray
        
        //change stack by replacing view controllers after ChatVC with ChatVC
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
    
    // MARK: - QMChatServiceDelegate
    
    func chatService(_ chatService: QMChatService, didUpdateChatDialogInMemoryStorage chatDialog: QBChatDialog) {
        
        if (chatDialog.id == self.dialog?.id) {
            self.dialog = chatDialog
        }
    }
}
