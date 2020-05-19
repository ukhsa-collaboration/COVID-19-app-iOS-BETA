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
    
    private var referenceCode: String?
    private var urlOpener: TestableUrlOpener!

    func inject(urlOpener: TestableUrlOpener, referenceCode: String?) {
        self.urlOpener = urlOpener
        self.referenceCode = referenceCode
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = {
            let title = UILabel()
            title.text = "Apply for a coronavirus test"
            title.textColor = UIColor(named: "NHS Blue")
            title.font = UIFont.preferredFont(forTextStyle: .headline)
            return title
        }()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReferenceCodeViewController {
            vc.inject(referenceCode: referenceCode)
        }
    }

    @IBAction func applyForTestTapped() {
        let url = ContentURLs.shared.applyForTest(referenceCode: referenceCode)
        urlOpener.open(url)
    }

}
