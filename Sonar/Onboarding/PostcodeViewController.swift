//
//  PostcodeViewController.swift
//  Sonar
//
//  Created by NHSX.
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
    @IBOutlet var postcodeField: UITextField!
    @IBOutlet var continueAccessoryView: UIView!

    override var inputAccessoryView: UIView {
        return continueAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    deinit {
        self.notificationCenter?.removeObserver(self)
    }

    func inject(persistence: Persisting, notificationCenter: NotificationCenter, continueHandler: @escaping () -> Void) {
        self.persistence = persistence
        self.notificationCenter = notificationCenter
        self.continueHandler = continueHandler
    }
    
    override func viewDidLoad() {
        // Hide the keyboard if the user taps anywhere else
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: postcodeField, action: #selector(resignFirstResponder)))
        
        notificationCenter.addObserver(self, selector: #selector(keyboardWasShown(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWasHidden(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    @IBAction func didTapContinue() {
        guard hasValidPostcode() else {
            showAlert()
            return
        }
        
        persistence.partialPostcode = enteredPostcode
        continueHandler()
    }
    
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
    
    private func showAlert() {
        let alert = UIAlertController(
            title: nil,
            message: "Please enter the first part of a valid postcode, e.g.: PO30, E2, M1, EH1, L36.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
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
}

extension PostcodeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard hasValidPostcode() else {
            textField.layer.borderWidth = 3
            textField.layer.borderColor = UIColor(named: "NHS Error")!.cgColor
            return false
        }

        didTapContinue()
        return false
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
