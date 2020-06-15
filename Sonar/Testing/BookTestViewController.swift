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

    private var result: LinkingIdResult!

    func inject(result: LinkingIdResult) {
        self.result = result
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var code: LinkingId?
        if case .success(let c) = result {
            code = c
        }
        bookTestLinkButton.url = ContentURLs.shared.bookTest(referenceCode: code)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReferenceCodeViewController {
            vc.inject(result: result)
        }
    }

}
