//
//  DrawerPresentation.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class DrawerPresentation: NSObject, UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DrawerPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class DrawerPresentationController: UIPresentationController {

    let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
        view.alpha = 0.0
        return view
    }()

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerBounds = containerView?.bounds, let presentedView = presentedView else { return .zero }

        let widthConstraint = presentedView.widthAnchor.constraint(equalToConstant: containerBounds.size.width)
        widthConstraint.isActive = true

        let size = presentedView.systemLayoutSizeFitting(CGSize(width: containerBounds.size.width, height: 0))

        presentedView.removeConstraint(widthConstraint)

        let origin = CGPoint(x: 0, y: containerBounds.size.height - size.height)
        return CGRect(origin: origin, size: size)
    }

    override init(presentedViewController presented: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presented, presenting: presentingViewController)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        guard let containerBounds = containerView?.bounds, let presentedView = presentedView else { return }

        presentedView.layer.masksToBounds = true
        presentedView.layer.cornerRadius = 16
        presentedView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        dimmingView.frame = containerBounds
        dimmingView.alpha = 0.0
        containerView?.insertSubview(dimmingView, at: 0)

        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 1.0
            })
        } else {
            dimmingView.alpha = 1.0
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            dimmingView.removeFromSuperview()
        }
    }

    override func dismissalTransitionWillBegin() {
        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0.0
            })
        } else {
            dimmingView.alpha = 0.0
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
        }
    }

}
