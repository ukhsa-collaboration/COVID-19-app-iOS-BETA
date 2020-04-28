//
//  DrawerPresentation.swift
//  Sonar
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
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override var frameOfPresentedViewInContainerView: CGRect {
        guard
            let containerView = containerView,
            let presentedView = presentedView
            else { return .zero }

        let safeBounds = containerView.bounds.inset(by: containerView.safeAreaInsets)

        let widthConstraint = presentedView.widthAnchor.constraint(equalToConstant: containerView.bounds.size.width)
        widthConstraint.isActive = true

        var size = presentedView.systemLayoutSizeFitting(CGSize(width: safeBounds.size.width, height: 0))
        size.height += containerView.safeAreaInsets.bottom

        presentedView.removeConstraint(widthConstraint)

        let origin = CGPoint(x: 0, y: containerView.bounds.size.height - size.height)
        return CGRect(origin: origin, size: size)
    }

    override init(presentedViewController presented: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presented, presenting: presentingViewController)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        guard let containerView = containerView, let presentedView = presentedView else { return }

        dimmingView.alpha = 0.0
        containerView.insertSubview(dimmingView, at: 0)
        NSLayoutConstraint.activate([
            dimmingView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            dimmingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            dimmingView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        presentedView.layer.masksToBounds = true
        presentedView.layer.cornerRadius = 8
        presentedView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard let presentedView = presentedView else { return }

        coordinator.animate(alongsideTransition: { _ in
            presentedView.frame = self.frameOfPresentedViewInContainerView
        }, completion: nil)
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
