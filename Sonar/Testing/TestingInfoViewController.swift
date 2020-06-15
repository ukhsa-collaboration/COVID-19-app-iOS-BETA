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
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var testResultMeansHeader: UILabel!
    @IBOutlet weak var testResultsButton: LinkButton!

    private var referenceCode: String?
    private var referenceError: String?
    private var scrollToTestResultMeaning: Bool!

    func inject(
        referenceCode: String?,
        referenceError: String?,
        scrollToTestResultMeaning: Bool = false
    ) {
        self.referenceCode = referenceCode
        self.referenceError = referenceError
        self.scrollToTestResultMeaning = scrollToTestResultMeaning
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        testResultsButton.url = contentUrls.testResults
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if scrollToTestResultMeaning {
            let scrollHeight = scrollView.frame.height
            let testResultMeansHeight = scrollView.contentSize.height - testResultMeansHeader.frame.minY
            let offset = scrollHeight - testResultMeansHeight
            UIView.animate(withDuration: 0.25) {
                self.scrollView.contentOffset = CGPoint(x: 0, y: self.testResultMeansHeader.frame.minY - offset)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReferenceCodeViewController {
            vc.inject(referenceCode: referenceCode, error: referenceError)
        }
    }
}
