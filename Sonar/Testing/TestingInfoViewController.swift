//
//  TestingInfoViewController.swift
//  Sonar
//
//  Created by NHSX on 4/25/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class TestingInfoViewController: UIViewController, Storyboarded {
    static let storyboardName = "TestingInfo"

    private let contentUrls = ContentURLs.shared
    
    @IBOutlet weak var testResultsButton: LinkButton!

    private var referenceCode: String?
    private var referenceError: String?

    func inject(referenceCode: String?, referenceError: String?) {
        self.referenceCode = referenceCode
        self.referenceError = referenceError
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        testResultsButton.url = contentUrls.testResults
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReferenceCodeViewController {
            vc.inject(referenceCode: referenceCode, error: referenceError)
        }
    }
}
