//
//  ApplyForTestViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class ApplyForTestViewController: UIViewController, Storyboarded {
    static let storyboardName = "ApplyForTest"

    @IBOutlet weak var applyLinkButton: LinkButton!

    private var referenceCode: String?

    func inject(referenceCode: String?) {
        self.referenceCode = referenceCode
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        applyLinkButton.url = ContentURLs.shared.applyForTest(referenceCode: referenceCode)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReferenceCodeViewController {
            vc.inject(referenceCode: referenceCode)
        }
    }

}
