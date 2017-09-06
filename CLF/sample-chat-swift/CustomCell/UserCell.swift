//
//  ActivitiesCell2.swift
//  Tied
//
//  Created by Admin on 21/06/16.
//  Copyright © 2016 DevStar. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {

    
    @IBOutlet weak var m_user_avatar: UIImageView!
    @IBOutlet weak var m_userName: UILabel!
    @IBOutlet weak var m_placename: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
