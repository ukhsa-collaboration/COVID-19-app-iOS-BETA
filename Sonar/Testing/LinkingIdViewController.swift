//
//  LinkingIdViewController.swift
//  Sonar
//
//  Created by NHSX on 5/14/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

private enum State {
    case fetching
    case failed
    case succeeded(linkingId: String)
}

class LinkingIdViewController: UIViewController, Storyboarded {
    static var storyboardName = "TestingInfo"

    @IBOutlet var fetchingWrapper: UIView!
    @IBOutlet var errorWrapper: UIView!
    @IBOutlet var referenceCodeWrapper: UIView!
    @IBOutlet var referenceCodeLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    private var linkingIdManager: LinkingIdManaging!
    private var uiQueue: TestableQueue!
    
    func inject(linkingIdManager: LinkingIdManaging, uiQueue: TestableQueue) {
        self.linkingIdManager = linkingIdManager
        self.uiQueue = uiQueue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        errorWrapper.isHidden = true
        referenceCodeWrapper.isHidden = true
        
        self.linkingIdManager.fetchLinkingId { linkingId in
            self.uiQueue.async {
                self.fetchingWrapper.isHidden = true

                if let linkingId = linkingId {
                    self.referenceCodeWrapper.isHidden = false
                    self.referenceCodeLabel.text = linkingId
                } else {
                    self.errorWrapper.isHidden = false
                }

                UIAccessibility.post(notification: .layoutChanged, argument: self.view)
            }
        }
    }

    @IBAction func copyTapped(_ sender: ButtonWithDynamicType) {
        UIPasteboard.general.string = referenceCodeLabel.text

        // This is an arbitrary dev animation to fade the
        // reference code view so the user knows we actually
        // did something when they tap "copy".
        UIView.animate(withDuration: 0.2, animations: {
            self.referenceCodeWrapper.alpha = 0.5
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, animations: {
                self.referenceCodeWrapper.alpha = 1
            })
        })
    }
}
