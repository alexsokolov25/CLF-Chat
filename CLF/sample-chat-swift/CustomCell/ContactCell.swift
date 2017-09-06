//
//  ActivitiesCell2.swift
//  Tied
//
//  Created by Admin on 21/06/16.
//  Copyright © 2016 DevStar. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {

    
    @IBOutlet weak var m_userName: UILabel!
    @IBOutlet weak var m_placeName: UILabel!
    @IBOutlet weak var m_btnVideoCall: UIButton!
    @IBOutlet weak var m_btnAudioCall: UIButton!
    @IBOutlet weak var m_btnText: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
