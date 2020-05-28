//
//  BookTestViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class BookTestViewController: UIViewController, Storyboarded {
    static let storyboardName = "BookTest"

    @IBOutlet weak var bookTestLinkButton: LinkButton!

    private var referenceCode: String?

    func inject(referenceCode: String?) {
        self.referenceCode = referenceCode
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bookTestLinkButton.url = ContentURLs.shared.bookTest(referenceCode: referenceCode)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReferenceCodeViewController {
            vc.inject(referenceCode: referenceCode)
        }
    }

}
