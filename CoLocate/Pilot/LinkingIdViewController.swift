//
//  LinkingIdViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class LinkingIdViewController: UIViewController {

    var persisting: Persisting!
    var linkingIdManager: LinkingIdManager!

    func inject(persisting: Persisting, linkingIdManager: LinkingIdManager) {
        self.persisting = persisting
        self.linkingIdManager = linkingIdManager
    }

    @IBOutlet weak var linkingIdLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewWillAppear(_ animated: Bool) {
        guard let linkingId = persisting.linkingId else {
            fetchLinkingId()
            return
        }

        linkingIdLabel.text = linkingId
    }

    private func fetchLinkingId() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()

        linkingIdManager.fetchLinkingId { linkingId in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.linkingIdLabel.text = linkingId
            }
        }
    }

}
