//
//  ActivitiesCell2.swift
//  Tied
//
//  Created by Admin on 21/06/16.
//  Copyright © 2016 DevStar. All rights reserved.
//

import UIKit

class MessageHistoryCell: UITableViewCell {

    
    @IBOutlet weak var m_profileImage: UIImageView!
    @IBOutlet weak var m_groupUser: UILabel!
    @IBOutlet weak var m_subject: UILabel!
    @IBOutlet weak var m_message: UILabel!
    @IBOutlet weak var m_time: UILabel!
    
    @IBOutlet weak var unreadMessageHolderView: UIView!
    @IBOutlet weak var unreadMessagesCounterLabelText : UILabel!
    
    var dialogID = ""
    
    @IBOutlet weak var avatarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var messagetHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTrailConstraint: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.unreadMessageHolderView.layer.cornerRadius = 12.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        
        let markerColor = self.unreadMessageHolderView.backgroundColor
        
        super.setSelected(selected, animated: animated)
        
        self.unreadMessageHolderView.backgroundColor = markerColor
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
        let markerColor = self.unreadMessageHolderView.backgroundColor
        
        super.setHighlighted(highlighted, animated: animated)
        
        self.unreadMessageHolderView.backgroundColor = markerColor
    }

}
