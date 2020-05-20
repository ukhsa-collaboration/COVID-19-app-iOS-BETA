//
//  DrawerPresentation.swift
//  Sonar
//
//  Created by NHSX on 4/20/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

class DrawerSegue: UIStoryboardSegue {
    private var retainedSelf: DrawerSegue? = nil

    let drawerPresentation = DrawerPresentation()

    override func perform() {
        retainedSelf = self
        destination.modalPresentationStyle = .custom
        destination.transitioningDelegate = drawerPresentation
        source.present(destination, animated: true, completion: nil)
    }
}

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

        // If the presented view contains a scroll view, we'll get a 0 back from trying to compute the desired size
        // of the presented view. Use the scroll view's only child instead.
        let sizeSource: UIView = {
            if let scrollView = presentedView.subviews.first as? UIScrollView {
                // We need to find the "real" child of the scroll view, but the scroll view's subviews also
                // include scroll indicators whihc we can't detect without using private APIs. So for now we
                // assume that the single "real" child of a scroll view is a UIStackView.
                if let realChild = scrollView.subviews.first(where: {$0.isKind(of: UIStackView.self)}) {
                    return realChild
                } else {
                    logger.warning("Did not find a stack view inside a scroll view. Falling back to using the outermost view for sizing, which is probably wrong.")
                }
            }
            
            return presentedView
        }()
         
        let widthConstraint = sizeSource.widthAnchor.constraint(equalToConstant: containerView.bounds.size.width)
        widthConstraint.isActive = true
        
        var size = sizeSource.systemLayoutSizeFitting(CGSize(width: safeBounds.size.width, height: 0))
        size.height = min(size.height, safeBounds.size.height - 32 /* Space down from the top a little */)
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


private let logger = Logger(label: "DrawerPresentation")
