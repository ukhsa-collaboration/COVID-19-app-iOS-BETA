//
//  ReconnectionDelayTableViewCell.swift
//  Sonar
//
//  Created by NHSX on 10.06.20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class ReconnectionDelayTableViewCell: UITableViewCell {
    
    @IBOutlet weak var reconnectionLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
