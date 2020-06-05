//
//  BluetoothIssueViewController.swift
//  Sonar
//
//  Created by NHSX on 4/21/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class BluetoothDeniedViewController: BluetoothIssueViewController {
    class func instantiate() -> BluetoothDeniedViewController {
        instantiate { $0.set(bluetooth: .denied) }
    }
}
class BluetoothOffViewController: BluetoothIssueViewController {
    class func instantiate() -> BluetoothOffViewController {
        instantiate { $0.set(bluetooth: .off) }
    }
}

class BluetoothIssueViewController: FixPermissionsViewController, Storyboarded {
    enum BluetoothType {
        case denied
        case off
    }
    
    static let storyboardName = "Onboarding"
    
    @IBOutlet weak var header: UILabel?
    
    private var bluetoothType: BluetoothType = .off
    
    func set(bluetooth type: BluetoothType) {
        bluetoothType = type
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switch bluetoothType {
        case .denied:
            header?.text = "BLUETOOTH_DENIED_HEADER".localized
        case .off:
            header?.text = "BLUETOOTH_OFF_HEADER".localized
        }
    }
}
