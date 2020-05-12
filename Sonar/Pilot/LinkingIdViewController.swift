//
//  LinkingIdViewController.swift
//  Sonar
//
//  Created by NHSX on 4/25/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class LinkingIdViewController: UIViewController, Storyboarded {
    static let storyboardName = "LinkingId"

    var persisting: Persisting!
    var linkingIdManager: LinkingIdManaging!

    func inject(persisting: Persisting, linkingIdManager: LinkingIdManaging) {
        self.persisting = persisting
        self.linkingIdManager = linkingIdManager
    }

    @IBOutlet weak var linkingIdLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!

    override func viewWillAppear(_ animated: Bool) {
        guard let linkingId = persisting.linkingId else {
            fetchLinkingId()
            return
        }

        linkingIdLabel.text = linkingId
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.performSegue(withIdentifier: "UnwindFromLinkingId", sender: nil)
        return true
    }

    private func fetchLinkingId() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()

        linkingIdManager.fetchLinkingId { linkingId in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                if let linkingId = linkingId {
                    self.errorLabel.isHidden = true
                    self.linkingIdLabel.isHidden = false
                    self.linkingIdLabel.text = linkingId
                } else {
                    self.linkingIdLabel.isHidden = true
                    self.errorLabel.isHidden = false
                }
            }
        }
    }

}
