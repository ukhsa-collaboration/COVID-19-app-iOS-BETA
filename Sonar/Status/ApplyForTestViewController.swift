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
    
    private var linkingIdManager: LinkingIdManaging!
    private var uiQueue: TestableQueue!
    private var urlOpener: TestableUrlOpener!
    private var refCodeVC: OldReferenceCodeViewController!

    func inject(linkingIdManager: LinkingIdManaging, uiQueue: TestableQueue, urlOpener: TestableUrlOpener) {
        self.linkingIdManager = linkingIdManager
        self.uiQueue = uiQueue
        self.urlOpener = urlOpener
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
        if let vc = segue.destination as? OldReferenceCodeViewController {
            vc.inject(linkingIdManager: linkingIdManager, uiQueue: uiQueue)
            self.refCodeVC = vc
        }
    }

    @IBAction func applyForTestTapped() {
        let url = ContentURLs.shared.applyForTest(referenceCode: refCodeVC.refCodeIfLoaded)
        urlOpener.open(url)
    }

}
