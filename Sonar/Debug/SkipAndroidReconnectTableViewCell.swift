//
//  SkipAndroidReconnectTableViewCell.swift
//  Sonar
//
//  Created by NHSX on 15.06.20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class SkipAndroidReconnectTableViewCell: UITableViewCell {

    @IBOutlet weak var skipAndroid: UISwitch!
    @IBOutlet weak var skipAndroidLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
