//
//  PostcodeViewController.swift
//  Sonar
//
//  Created by NHSX on 4/10/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

fileprivate let maxLength = 4

class PostcodeViewController: UIViewController, Storyboarded {
    static var storyboardName = "Onboarding"
    
    private var persistence: Persisting! = nil
    private var notificationCenter: NotificationCenter! = nil
    private var continueHandler: (() -> Void)! = nil

    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet var postcodeError: UILabel!
    @IBOutlet var postcodeField: UITextField!
    @IBOutlet var postcodeDetail: UILabel!
    @IBOutlet var continueAccessoryView: UIView!
    @IBOutlet var continueButton: PrimaryButton!

    override var inputAccessoryView: UIView {
        return continueAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    func inject(persistence: Persisting, notificationCenter: NotificationCenter, continueHandler: @escaping () -> Void) {
        self.persistence = persistence
        self.notificationCenter = notificationCenter
        self.continueHandler = continueHandler
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        postcodeError.isHidden = true
        
        let text = postcodeDetail.text!
        let range = text.range(of: "not")
        let nsrange = NSRange(range!, in: text)
        let attrText = NSMutableAttributedString(string: text)
        attrText.addAttribute(NSAttributedString.Key.font, value: UIFont.preferredFont(forTextStyle: .headline), range: nsrange)
        postcodeDetail.attributedText = attrText

        // Hide the keyboard if the user taps anywhere else
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: postcodeField, action: #selector(resignFirstResponder)))
        
        notificationCenter.addObserver(self, selector: #selector(keyboardWasShown(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWasHidden(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(updateBasedOnAccessibilityDisplayChanges(_:)), name: UIAccessibility.invertColorsStatusDidChangeNotification, object: nil)
    }

    // MARK: - IBActions

    @IBAction func didTapContinue() {
        guard hasValidPostcode() else {
            showPostcodeError()
            return
        }

        postcodeError.isHidden = true
        persistence.partialPostcode = enteredPostcode
        continueHandler()
    }

    @objc private func keyboardWasShown(_ notification: Notification) {
        guard let kbFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbFrame.size.height, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets

        var visibleRegion = view.frame
        visibleRegion.size.height -= kbFrame.height

        if !visibleRegion.contains(postcodeField.frame.origin) {
            scrollView.scrollRectToVisible(postcodeField.frame, animated: true)
        }
    }

    @objc private func keyboardWasHidden(_ notification: Notification) {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }

    @objc private func updateBasedOnAccessibilityDisplayChanges(_ notification: Notification) {
        continueButton.updateBasedOnAccessibilityDisplayChanges()
    }

    // MARK: - Private

    private var enteredPostcode: String {
        get {
            guard let rawPostcode = postcodeField?.text else { return "" }
            return rawPostcode
                .trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                .uppercased()
        }
    }
    
    private func hasValidPostcode() -> Bool {
        return PostcodeValidator.isValid(enteredPostcode)
    }
    
    private func showPostcodeError() {
        scroll(after: {
            self.postcodeError.isHidden = false
            self.postcodeError.text = "Please enter the first part of a valid postcode. For example: PO30, E2, M1, EH1, L36".localized

            self.postcodeError.layer.borderWidth = 3
            self.postcodeError.layer.borderColor = UIColor(named: "NHS Error")!.cgColor
        }, to: { () -> UIView in
            // If we just scroll the error message into view, the field will sometimes be
            // scrolled out of view. That's usually undesirable -- we want both to be visible.
            // But if the screen is too short to accomodate both (e.g. large fonts + landscape)
            // then it's better to show the entire error message.
            let adjustedFieldFrame = self.postcodeField.convert(self.postcodeField.bounds, to: self.postcodeError)
            let desiredHeight = adjustedFieldFrame.size.height + adjustedFieldFrame.origin.y
            let availableHeight = self.scrollView.bounds.height - self.scrollView.contentInset.bottom - self.scrollView.contentInset.top
            
            if desiredHeight < availableHeight {
                return self.postcodeField
            } else {
                return self.postcodeError
            }
        })
    }
}

extension PostcodeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapContinue()

        return true
    }
        
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString: String) -> Bool {
        let existingLength = textField.text?.count ?? 0
        return existingLength - range.length + replacementString.count <= maxLength
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.borderWidth = 3
        textField.layer.borderColor = UIColor(named: "NHS Dark Blue")!.cgColor
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor(named: "NHS Text")!.cgColor
    }
}

class ContinueButtonAccessoryView: UIView {
    override var intrinsicContentSize: CGSize {
        // This needs to be zero or else iOS adds
        // a height constraint onto the view based
        // on the frame height from Interface Builder.
        .zero
    }
}
