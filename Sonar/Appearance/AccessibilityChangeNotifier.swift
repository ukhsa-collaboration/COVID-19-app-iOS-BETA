//
//  AccessibilityChangeNotifier.swift
//  Sonar
//
//  Created by NHSX on 6/2/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class AccessibilityChangeNotifier {
    private let uiQueue: TestableQueue
    private let rootViewController: UIViewController
    
    init(notificationCenter: NotificationCenter, uiQueue: TestableQueue, rootViewController: UIViewController) {
        self.uiQueue = uiQueue
        self.rootViewController = rootViewController
        
        notificationCenter.addObserver(self, selector: #selector(handleNotification(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleNotification(_:)), name: UIAccessibility.invertColorsStatusDidChangeNotification, object: nil)

        // In iOS 13, UIAccessibility.invertColorsStatusDidChangeNotification doesn't fire when smart invert
        // is turned on, and the invert state can't be reliably detected until after it fires.
        // To work around those bugs, we assume that the smart invert setting might have changed any time
        // we come back from the background.
        notificationCenter.addObserver(self, selector: #selector(handleNotification(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func handleNotification(_ notification: Notification) {
        notifyViews()
    }
    
    private func notifyViews() {
        uiQueue.async {
            self.recursivelyNotify(view: self.rootViewController.view)
            
            for vc in self.allPresentedViewControllers(from: self.rootViewController) {
                self.recursivelyNotify(view: vc.view)
            }
        }
    }
    
    private func recursivelyNotify(view: UIView) {
        if let updateable = view as? UpdatesBasedOnAccessibilityDisplayChanges {
            updateable.updateBasedOnAccessibilityDisplayChanges()
        }
        
        for v in view.subviews {
            recursivelyNotify(view: v)
        }
    }
    
    private func allPresentedViewControllers(from vc: UIViewController) -> [UIViewController] {
        var presentedViewControllers = vc.presentedViewController.map { [$0] } ?? []
        presentedViewControllers.append(contentsOf: vc.children.flatMap { allPresentedViewControllers(from: $0) })
        return presentedViewControllers
    }
}
