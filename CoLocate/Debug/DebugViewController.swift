//
//  DebugViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

protocol DebugViewControllerDelegate: class {
    func debugViewControllerWantsToExit(_ sender: DebugViewController) -> Void
}

class DebugViewController: UIViewController {
    
    weak var delegate: DebugViewControllerDelegate?

    @IBAction func exitTapped() {
        delegate?.debugViewControllerWantsToExit(self)
    }
    
}
