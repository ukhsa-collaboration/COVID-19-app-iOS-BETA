//
//  PotentialViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class PotentialViewController: UIViewController, Storyboarded {

    static let storyboardName = "Potential"

    @IBOutlet weak var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.isNavigationBarHidden = true

        let url = Bundle.main.url(forResource: "Potential", withExtension: "rtf")!
        label.attributedText = try! NSAttributedString(
            url: url,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
    }

    @IBAction func resultCodeTapped(_ sender: PrimaryButton) {
    }

}
