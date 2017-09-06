//
//  SignupViewController.swift
//  CLF-Chat
//
//  Created by Admin on 11/08/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class MessageTableViewCellModel: NSObject {
    
    var detailTextLabelText: String = ""
    var textLabelText: String = ""
    var unreadMessagesCounterLabelText : String?
    var unreadMessagesCounterHiden = true
    var dialogIcon : UIImage?
    var lastDate : String = ""
    var groupUserLabel : String = ""
    
    init(dialog: QBChatDialog, users: [QBUUser]) {
        super.init()
        
        switch (dialog.type){
            case .publicGroup:
                self.detailTextLabelText = "SA_STR_PUBLIC_GROUP".localized
            case .group:
                self.detailTextLabelText = "SA_STR_GROUP".localized
            case .private:
                self.detailTextLabelText = "SA_STR_PRIVATE".localized
                
                if dialog.recipientID == -1 {
                    return
                }
                
                // Getting recipient from users service.
                if let recipient = ServicesManager.instance().usersService.usersMemoryStorage.user(withID: UInt(dialog.recipientID)) {
                    self.textLabelText = recipient.fullName ?? recipient.email!
                }
        }
        
        if self.textLabelText.isEmpty {
            // group chat
            
            if let dialogName = dialog.name {
                self.textLabelText = dialogName
            }
        }
        
        lastDate = (dialog.updatedAt?.covertToString())!

        var strGroupID : String = ""
        let cntOccupant : Int = (dialog.occupantIDs?.count)!

        for elem in users {
            
            var index : Int = 0
            
            for number in dialog.occupantIDs! {
                index += 1
                let chatID = NSNumber(value: elem.id)

                if NSNumber(value: dialog.userID) == number { continue }
                if index > 4 { continue }
                if number == chatID {
                    strGroupID = strGroupID + elem.fullName! + ", "
                }
            }
        }
        if cntOccupant > 4 {
            strGroupID = strGroupID + "+" + String.init(format: "%d", (cntOccupant - 4))
            groupUserLabel = strGroupID
        } else {
            if strGroupID != "" {
                let index1 = strGroupID.index(strGroupID.endIndex, offsetBy: -2)
                groupUserLabel = strGroupID.substring(to: index1)
            }
        }
        
        // Unread messages counter label
        
        if (dialog.unreadMessagesCount > 0) {
            
            var trimmedUnreadMessageCount : String
            
            if dialog.unreadMessagesCount > 99 {
                trimmedUnreadMessageCount = "99+"
            } else {
                trimmedUnreadMessageCount = String(format: "%d", dialog.unreadMessagesCount)
            }
            
            self.unreadMessagesCounterLabelText = trimmedUnreadMessageCount
            self.unreadMessagesCounterHiden = false
            
        }
        else {
            
            self.unreadMessagesCounterLabelText = nil
            self.unreadMessagesCounterHiden = true
        }
        
        // Dialog icon
        
        if dialog.type == .private {
            self.dialogIcon = UIImage(named: "user")
        }
        else {
            self.dialogIcon = UIImage(named: "group")
        }
    }
}

protocol LogoutDelegate {
    func logout()
}

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, QMChatServiceDelegate, QMChatConnectionDelegate, QMAuthServiceDelegate, LogoutDelegate, UISearchBarDelegate, QMUsersServiceDelegate {
    
    
    var bMyGroup : Bool = false
    var bloadedView : Bool = false
    var bCompany : Bool = true
    var searchActive : Int = 0
    
    @IBOutlet weak var alertArchivedCntView: UIView!
    @IBOutlet weak var lblArchivedCnt: UILabel!
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageTableView: UITableView!
    
    @IBOutlet weak var contactView: UIView!
    @IBOutlet weak var subMyGroupView: UIView!
    @IBOutlet weak var myGroupTableView: UITableView!
    
    @IBOutlet weak var subAllContactView: UIView!
    @IBOutlet weak var allContactTableView: UITableView!
    @IBOutlet weak var searchBarView: UISearchBar!
    @IBOutlet weak var lblSortMode: UILabel!
    
    
    @IBOutlet weak var archivedView: UIView!
    @IBOutlet weak var archivedTableView: UITableView!
    
    @IBOutlet weak var leftConstraints: NSLayoutConstraint!
    
    var groupMember:[GroupMember] = []
    
    var memberByName:[GroupMember] = []
    var memberSortByName:[GroupMember] = []
    var filter_memberByName:[GroupMember] = []
    
    var section_names = [String]()
    var section_allContact : [[GroupMember]] = []
    
    var filter_section_names = [String]()
    var filter_section_allContact : [[GroupMember]] = []
    
    private var didEnterBackgroundDate: NSDate?
    private var observer: NSObjectProtocol?
    
    var dialog: QBChatDialog?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        ServicesManager.instance().chatService.addDelegate(self)
        
        ServicesManager.instance().authService.add(self)
        
        ServicesManager.instance().usersService.add(self)
        
        self.observer = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { (notification) -> Void in
            
            if !QBChat.instance.isConnected {
                SVProgressHUD.show(withStatus: "SA_STR_CONNECTING_TO_CHAT".localized, maskType: SVProgressHUDMaskType.clear)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.didEnterBackgroundNotification), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
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
        
        contactView.isHidden = true
        archivedView.isHidden = true
        
        subAllContactView.isHidden = true
        
        InterfaceManager.makeRadiusControl(alertArchivedCntView, cornerRadius: 10.0, withColor: UIColor.clear, borderSize: 0.0)
        
        searchBarView.delegate = self
        
        self.initConstraint()
        makeTableViewSetup(0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        
        self.getGroupMember()
        
        if (QBChat.instance.isConnected) {
            self.getDialogs()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        self.myGroupTableView.reloadData()
        self.allContactTableView.reloadData()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismissKeyboard()
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.view.endEditing(true)
    }
    
    func initConstraint() {
        self.view.layoutIfNeeded()
    }
    
    func makeTableViewSetup(_ fBottomInset: CGFloat) {
        
        self.messageTableView.delegate = self
        self.messageTableView.dataSource = self
        
        self.messageTableView.tableFooterView = UIView()
        self.messageTableView.backgroundColor = UIColor.clear
        
        let edgeInsets = UIEdgeInsetsMake(0.0, 0.0, fBottomInset, 0.0)
        self.messageTableView.contentInset = edgeInsets
        self.messageTableView.scrollIndicatorInsets = edgeInsets
        
        self.messageTableView.setNeedsLayout()
        self.messageTableView.layoutIfNeeded()
        
        self.myGroupTableView.delegate = self
        self.myGroupTableView.dataSource = self
        
        self.myGroupTableView.tableFooterView = UIView()
        self.myGroupTableView.backgroundColor = UIColor.clear
        
        self.myGroupTableView.contentInset = edgeInsets
        self.myGroupTableView.scrollIndicatorInsets = edgeInsets
        
        self.myGroupTableView.setNeedsLayout()
        self.myGroupTableView.layoutIfNeeded()
        
        self.allContactTableView.delegate = self
        self.allContactTableView.dataSource = self
        
        self.allContactTableView.tableFooterView = UIView()
        self.allContactTableView.backgroundColor = UIColor.clear
        
        self.allContactTableView.contentInset = edgeInsets
        self.allContactTableView.scrollIndicatorInsets = edgeInsets
        
        self.allContactTableView.setNeedsLayout()
        self.allContactTableView.layoutIfNeeded()
        
        self.archivedTableView.delegate = self
        self.archivedTableView.dataSource = self
        
        self.archivedTableView.tableFooterView = UIView()
        self.archivedTableView.backgroundColor = UIColor.clear
        
        self.archivedTableView.contentInset = edgeInsets
        self.archivedTableView.scrollIndicatorInsets = edgeInsets
        
        self.archivedTableView.setNeedsLayout()
        self.archivedTableView.layoutIfNeeded()
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
                    
                    print(responseJSON)
                    
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
                                        
                                        self.memberByName.append(obj)
                                        
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
                    
                    self.memberSortByName = self.memberByName.sorted(by: {$0.fname! < $1.fname!})
                    
                    self.allContactTableView.reloadData()
                }
                
        }, errBlock: {(errorString) -> Void in
            TheInterfaceManager.showLocalValidationError(self, errorMessage: errorString)
            LoadingOverlay.shared.hideOverlayView()
        })
    }
    
    @IBAction func actionProfile(_ sender: Any) {
        let viewCon = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController
        viewCon?.delegate = self
        self.navigationController?.pushViewController(viewCon!, animated: true)
    }
    
    @IBAction func actionNewMessage(_ sender: Any) {
        let viewCon = self.storyboard?.instantiateViewController(withIdentifier: "NewMessageViewController")
        self.navigationController?.pushViewController(viewCon!, animated: true)
    }
    
    @IBAction func actionSelTab(_ sender: UIButton) {
        if sender.tag == 10 {
            messageView.isHidden = false
            contactView.isHidden = true
            archivedView.isHidden = true
            
            UIView.animate(withDuration: 0.3, animations: {
                self.leftConstraints.constant = 0
                self.view.layoutIfNeeded()
            }, completion: { (bFinished: Bool) -> Void in
                if (bFinished) {
                    
                }
            })
        } else if sender.tag == 11 {
            messageView.isHidden = true
            contactView.isHidden = false
            archivedView.isHidden = true
            
            UIView.animate(withDuration: 0.3, animations: {
                self.leftConstraints.constant = UIScreen.main.bounds.size.width / 3.0
                self.view.layoutIfNeeded()
            }, completion: { (bFinished: Bool) -> Void in
                if (bFinished) {
                    
                }
            })
            
            self.getAllContacts()
            
        } else {
            messageView.isHidden = true
            contactView.isHidden = true
            archivedView.isHidden = false
            
            UIView.animate(withDuration: 0.3, animations: {
                self.leftConstraints.constant = UIScreen.main.bounds.size.width / 3.0 * 2
                self.view.layoutIfNeeded()
            }, completion: { (bFinished: Bool) -> Void in
                if (bFinished) {
                    
                }
            })
        }
    }

    @IBAction func actionSelectChange(_ sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0 {
            bMyGroup = true
            
            subMyGroupView.isHidden = false
            subAllContactView.isHidden = true
        } else {
            bMyGroup = false

            subMyGroupView.isHidden = true
            subAllContactView.isHidden = false
        }
    }
    
    @IBAction func actionAddContact(_ sender: Any) {
        let viewCon = self.storyboard?.instantiateViewController(withIdentifier: "AddNewUserViewController")
        self.navigationController?.pushViewController(viewCon!, animated: true)
    }
    
    @IBAction func actionSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.lblSortMode.text = "Sort by Company"
            bCompany = true
        } else {
            self.lblSortMode.text = "Sort by Name"
            bCompany = false
        }
        
        self.allContactTableView.reloadData()
    }
    
    func logout() {
        
        if !QBChat.instance.isConnected {
            
            SVProgressHUD.showError(withStatus: "Error")
            return
        }
        
        SVProgressHUD.show(withStatus: "SA_STR_LOGOUTING".localized, maskType: SVProgressHUDMaskType.clear)
        
        QBChat.instance.disconnect(completionBlock: { (error) -> Void in
            
            NotificationCenter.default.removeObserver(self)
            
            if self.observer != nil {
                NotificationCenter.default.removeObserver(self.observer!)
                self.observer = nil
            }

            ServicesManager.instance().chatService.removeDelegate(self)
            ServicesManager.instance().authService.remove(self)
            
            ServicesManager.instance().lastActivityDate = nil;
            
            let viewCon = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController")
            self.navigationController?.pushViewController(viewCon!, animated: true)
            
            SVProgressHUD.showSuccess(withStatus: "SA_STR_COMPLETED".localized)
        })
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
        
        if bCompany {   //Sort by company
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
        } else {    //Sort by name
            
            if searchText == "" {
                searchActive = 0;
            } else {
                searchActive = 1;
                filter_memberByName = []
                for item in memberSortByName {
                    let name : String = String.init(format: "%@ %@", item.fname!, item.lname!)
                    
                    if name.range(of: searchText, options: .caseInsensitive) != nil {
                        filter_memberByName.append(item)
                    }
                }
            }
        }
        
        self.allContactTableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if tableView == allContactTableView {
            if bCompany {
                if searchActive != 0 {
                    return filter_section_names[section]
                }

                return section_names[section]
            }
        }
        
        return ""
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == allContactTableView {
            if bCompany {
                return 50.0
            }
        }
        
        return 0.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if tableView == allContactTableView {
            if bCompany {
                if searchActive != 0 {
                    return filter_section_names.count
                }
                
                return section_names.count
            }
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == messageTableView || tableView == archivedTableView {
            return 90.0
        }
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == messageTableView {
            if let dialogs = self.dialogs() {
                return dialogs.count
            }
        } else if tableView == archivedTableView {
            return 0
        } else if tableView == myGroupTableView {
            return self.groupMember.count
        } else if tableView == allContactTableView {
            if bCompany {
                if searchActive != 0 {
                    return filter_section_allContact[section].count
                }
                return section_allContact[section].count
            } else {
                if searchActive != 0 {
                    return self.filter_memberByName.count
                }
                return self.memberByName.count
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == messageTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellID.MessageHistoryCell, for: indexPath as IndexPath) as! MessageHistoryCell
            
            if ((self.dialogs()?.count)! < indexPath.row) {
                return cell
            }
            
            guard let chatDialog = self.dialogs()?[indexPath.row] else {
                return cell
            }
            
            if chatDialog.occupantIDs?.count == 2 {
                cell.m_groupUser.isHidden = true
                cell.avatarTopConstraint.constant = 15
                cell.layoutIfNeeded()
            } else {
                cell.m_groupUser.isHidden = false
                cell.avatarTopConstraint.constant = 2
                cell.layoutIfNeeded()
            }
            
            cell.tag = indexPath.row
            cell.dialogID = chatDialog.id!
            
            let cellModel = MessageTableViewCellModel (dialog: chatDialog, users: TheGlobalPoolManager.allUsers)
            
            cell.m_profileImage.image = cellModel.dialogIcon
            cell.m_message?.text = chatDialog.lastMessageText
            cell.m_subject?.text = cellModel.textLabelText
            cell.m_groupUser?.text = cellModel.groupUserLabel
            cell.m_time?.text = cellModel.lastDate
            cell.unreadMessagesCounterLabelText.text = cellModel.unreadMessagesCounterLabelText
            cell.unreadMessageHolderView.isHidden = cellModel.unreadMessagesCounterHiden
            
            if cellModel.unreadMessagesCounterHiden {
                cell.messageTrailConstraint.constant = -30
            } else {
                cell.messageTrailConstraint.constant = 7
            }
            
            return cell
        } else if tableView == archivedTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellID.ArchivedCell, for: indexPath as IndexPath) as! ArchivedCell
            
            return cell
        } else {
            if tableView == myGroupTableView {
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellID.ContactCell, for: indexPath as IndexPath) as! ContactCell
                
                let member = self.groupMember[indexPath.row]
                
                cell.m_userName.text = String.init(format: "%@ %@", member.fname!, member.lname!)
                cell.m_placeName.isHidden = true
                
                let somestring = member.chatID
                if somestring != "" {
                    if let myInteger = Int(somestring!) {
                        
//                        cell.m_btnVideoCall.tag = indexPath.row
//                        cell.m_btnVideoCall.addTarget(self, action: #selector(HomeViewController.actionVideoCall(_:)), for: .touchUpInside)
//                        
//                        cell.m_btnAudioCall.tag = indexPath.row
//                        cell.m_btnAudioCall.addTarget(self, action: #selector(HomeViewController.actionAudioCall(_:)), for: .touchUpInside)
                        
                        cell.m_btnText.tag = indexPath.row
                        cell.m_btnText.addTarget(self, action: #selector(HomeViewController.actionTextChat(_:)), for: .touchUpInside)
                    }
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellID.ContactCell, for: indexPath as IndexPath) as! ContactCell
                
                var member : GroupMember? = nil
                if bCompany {
                    if searchActive != 0 {
                        member = self.filter_section_allContact[indexPath.section][indexPath.row]
                    } else {
                        member = self.section_allContact[indexPath.section][indexPath.row]
                    }
                } else {
                    if searchActive != 0 {
                        member = self.filter_memberByName[indexPath.row]
                    } else {
                        member = self.memberSortByName[indexPath.row]
                    }
                }
                
                cell.m_userName.text = String.init(format: "%@ %@", (member?.fname!)!, (member?.lname!)!)
                cell.m_placeName.text = String.init(format: "(%@)", (member?.placename!)!)
                
//                cell.m_btnVideoCall.tag = (member?.profileID)!
//                cell.m_btnVideoCall.addTarget(self, action: #selector(HomeViewController.actionVideoCall(_:)), for: .touchUpInside)
//                
//                cell.m_btnAudioCall.tag = (member?.profileID)!
//                cell.m_btnAudioCall.addTarget(self, action: #selector(HomeViewController.actionAudioCall(_:)), for: .touchUpInside)
                
                cell.m_btnText.tag = indexPath.row
                cell.m_btnText.addTarget(self, action: #selector(HomeViewController.actionTextChat(_:)), for: .touchUpInside)
                
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == messageTableView || tableView == archivedTableView {
            
            guard let dialog = self.dialogs()?[indexPath.row] else {
                return
            }
            
            let viewCon = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
            viewCon?.dialog = dialog
            self.navigationController?.pushViewController(viewCon!, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if tableView == messageTableView {
            return true
        }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let dialog = self.dialogs()?[indexPath.row] else {
            return nil
        }
        
        let share = UITableViewRowAction(style: .normal, title: "Archive") { action, index in
            
            // create the alert
            let alert = UIAlertController(title: "SA_STR_WARNING".localized, message: "SA_STR_DO_YOU_REALLY_WANT_TO_ARCHIVE_SELECTED_DIALOG".localized, preferredStyle: .alert)
            
            // add the actions (buttons)
            alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler:  { action in
                
                SVProgressHUD.show(withStatus: "SA_STR_ARCHIVING".localized, maskType: SVProgressHUDMaskType.clear)
                
                let deleteDialogBlock = { (dialog: QBChatDialog!) -> Void in
                    
                    // Deletes dialog from server and cache.
                    ServicesManager.instance().chatService.deleteDialog(withID: dialog.id!, completion: { (response) -> Void in
                        
                        guard response.isSuccess else {
                            SVProgressHUD.showError(withStatus: "SA_STR_ERROR_ARCHIVEING".localized)
                            print(response.error?.error)
                            return
                        }
                        
                        SVProgressHUD.showSuccess(withStatus: "SA_STR_ARCHIVED".localized)
                    })
                }
                
                if dialog.type == QBChatDialogType.private {
                    
                    deleteDialogBlock(dialog)
                    
                }
                else {
                    // group
                    let occupantIDs = dialog.occupantIDs!.filter({ (number) -> Bool in
                        
                        return number.uintValue != ServicesManager.instance().currentUser.id
                    })
                    
                    dialog.occupantIDs = occupantIDs
                    let userLogin = ServicesManager.instance().currentUser.login ?? ""
                    let notificationMessage = "User \(userLogin) " + "SA_STR_USER_HAS_ARCHIVE".localized
                    // Notifies occupants that user left the dialog.
                    ServicesManager.instance().chatService.sendNotificationMessageAboutLeaving(dialog, withNotificationText: notificationMessage, completion: { (error) -> Void in
                        deleteDialogBlock(dialog)
                    })
                }
                
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
        share.backgroundColor = UIColor.red
        
        return [share]
    }
    
    func actionVideoCall(_ sender: UIButton) {
        print(sender.tag)
        
        let member = self.groupMember[sender.tag]
        
        let somestring = member.chatID
        let myInteger = Int(somestring!)
        
        if let _ = TheVideoCallManager.callWithConferenceType(.video, opponentID: NSNumber(value: myInteger!)) {
            TheGlobalPoolManager.bCallerUser = true
            
            let viewCon: VideoCallViewController = self.storyboard?.instantiateViewController(withIdentifier: "videocallview") as! VideoCallViewController
            viewCon.strOpponentUserName = "Test User"
//            viewCon.strOpponentUserProfileUrl = convo.otherUser.profilePicUrl
            
            viewCon.bOutComingCall = true
            
            self.present(viewCon, animated: true, completion: nil)
        }
    }
    
    func actionAudioCall(_ sender: UIButton) {
        print(sender.tag)   //sender.tag is ChatID
        
        let member = self.groupMember[sender.tag]
        
        let somestring = member.chatID
        let myInteger = Int(somestring!)
        
        if let _ = TheVideoCallManager.callWithConferenceType(.audio, opponentID: NSNumber(value: myInteger!)) {
            TheGlobalPoolManager.bCallerUser = true
            
            let viewCon: VideoCallViewController = self.storyboard?.instantiateViewController(withIdentifier: "videocallview") as! VideoCallViewController
            viewCon.strOpponentUserName = "Test User"
            //            viewCon.strOpponentUserProfileUrl = convo.otherUser.profilePicUrl
            
            viewCon.bOutComingCall = true
            
            self.present(viewCon, animated: true, completion: nil)
        }
    }
    
    func actionTextChat(_ sender: UIButton) {
        print(sender.tag)   //sender.tag is ChatID
        
        let member = self.groupMember[sender.tag]
        
        self.gotoChat(member)
    }
    
    func gotoChat(_ member: GroupMember) {
        var users: [QBUUser] = []
        
        let user:QBUUser = QBUUser()
        user.id = UInt(member.chatID!)!
        user.email = member.email
        user.password = "4GM@k3$G*S"
        user.fullName = String.init(format: "%@ %@", member.fname!, member.lname!)
        
        users.append(user)
        
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
    
    func openNewDialog(dialog: QBChatDialog!) {
        self.dialog = dialog
        
        let viewCon = self.storyboard!.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        viewCon.dialog = dialog
        self.navigationController?.pushViewController(viewCon, animated: true)
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
    
    func updatedMessageWithUsers(users: [QBUUser],isNewDialog:Bool) -> String {
        
        let dialogMessage = isNewDialog ? "SA_STR_CREATE_NEW".localized : "SA_STR_ADDED".localized
        
        var message: String = (TheGlobalPoolManager.currentUser?.fname)! + " " + (TheGlobalPoolManager.currentUser?.lname)! + dialogMessage + " "
        for user: QBUUser in users {
            message = "\(message)\(user.fullName!),"
        }
        message.remove(at: message.index(before: message.endIndex))
        return message
    }
    
    // MARK: - Notification handling
    
    func didEnterBackgroundNotification() {
        self.didEnterBackgroundDate = NSDate()
    }
    
    // MARK: - DataSource Action
    
    func getDialogs() {
        
        if let lastActivityDate = ServicesManager.instance().lastActivityDate {
            
            ServicesManager.instance().chatService.fetchDialogsUpdated(from: lastActivityDate as Date, andPageLimit: kDialogsPageLimit, iterationBlock: { (response, dialogObjects, dialogsUsersIDs, stop) -> Void in
                
            }, completionBlock: { (response) -> Void in
                
                if (response.isSuccess) {
                    
                    ServicesManager.instance().lastActivityDate = NSDate()
                }
            })
        }
        else {
            
            SVProgressHUD.show(withStatus: "SA_STR_LOADING_DIALOGS".localized, maskType: SVProgressHUDMaskType.clear)
            
            ServicesManager.instance().chatService.allDialogs(withPageLimit: kDialogsPageLimit, extendedRequest: nil, iterationBlock: { (response: QBResponse?, dialogObjects: [QBChatDialog]?, dialogsUsersIDS: Set<NSNumber>?, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                
            }, completion: { (response: QBResponse?) -> Void in
                
                guard response != nil && response!.isSuccess else {
                    SVProgressHUD.showError(withStatus: "SA_STR_FAILED_LOAD_DIALOGS".localized)
                    return
                }
                
                SVProgressHUD.showSuccess(withStatus: "SA_STR_COMPLETED".localized)
                ServicesManager.instance().lastActivityDate = NSDate()
            })
        }
    }
    
    // MARK: - DataSource
    
    func dialogs() -> [QBChatDialog]? {
        
        // Returns dialogs sorted by updatedAt date.
        return ServicesManager.instance().chatService.dialogsMemoryStorage.dialogsSortByUpdatedAt(withAscending: false)
    }
    
    // MARK: - QMChatServiceDelegate
    
    func chatService(_ chatService: QMChatService, didUpdateChatDialogInMemoryStorage chatDialog: QBChatDialog) {
        
        self.reloadTableViewIfNeeded()
    }
    
    func chatService(_ chatService: QMChatService,didUpdateChatDialogsInMemoryStorage dialogs: [QBChatDialog]){
        
        self.reloadTableViewIfNeeded()
    }
    
    func chatService(_ chatService: QMChatService, didAddChatDialogsToMemoryStorage chatDialogs: [QBChatDialog]) {
        
        self.reloadTableViewIfNeeded()
    }
    
    func chatService(_ chatService: QMChatService, didAddChatDialogToMemoryStorage chatDialog: QBChatDialog) {
        
        self.reloadTableViewIfNeeded()
    }
    
    func chatService(_ chatService: QMChatService, didDeleteChatDialogWithIDFromMemoryStorage chatDialogID: String) {
        
        self.reloadTableViewIfNeeded()
    }
    
    func chatService(_ chatService: QMChatService, didAddMessagesToMemoryStorage messages: [QBChatMessage], forDialogID dialogID: String) {
        
        self.reloadTableViewIfNeeded()
    }
    
    func chatService(_ chatService: QMChatService, didAddMessageToMemoryStorage message: QBChatMessage, forDialogID dialogID: String){
        
        self.reloadTableViewIfNeeded()
    }
    
    // MARK: QMChatConnectionDelegate
    
    func chatServiceChatDidFail(withStreamError error: Error) {
        SVProgressHUD.showError(withStatus: error.localizedDescription)
    }
    
    func chatServiceChatDidAccidentallyDisconnect(_ chatService: QMChatService) {
        SVProgressHUD.showError(withStatus: "SA_STR_DISCONNECTED".localized)
    }
    
    func chatServiceChatDidConnect(_ chatService: QMChatService) {
        SVProgressHUD.showSuccess(withStatus: "SA_STR_CONNECTED".localized, maskType:.clear)
        if !ServicesManager.instance().isProcessingLogOut! {
            self.getDialogs()
        }
    }
    
    func chatService(_ chatService: QMChatService,chatDidNotConnectWithError error: Error){
        SVProgressHUD.showError(withStatus: error.localizedDescription)
    }
    
    
    func chatServiceChatDidReconnect(_ chatService: QMChatService) {
        SVProgressHUD.showSuccess(withStatus: "SA_STR_CONNECTED".localized, maskType: .clear)
        if !ServicesManager.instance().isProcessingLogOut! {
            self.getDialogs()
        }
    }
    
    // MARK: - Helpers
    func reloadTableViewIfNeeded() {
        if !ServicesManager.instance().isProcessingLogOut! {
            self.messageTableView.reloadData()
        }
    }
}
