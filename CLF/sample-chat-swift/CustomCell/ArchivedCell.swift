//
//  ActivitiesCell2.swift
//  Tied
//
//  Created by Admin on 21/06/16.
//  Copyright © 2016 DevStar. All rights reserved.
//

import UIKit

class ArchivedCell: UITableViewCell {

    @IBOutlet weak var m_profileImage: UIImageView!
    @IBOutlet weak var m_groupUser: UILabel!
    @IBOutlet weak var m_subject: UILabel!
    @IBOutlet weak var m_message: UILabel!
    @IBOutlet weak var m_time: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        
    }
}
