//
//  PostcodeViewController.swift
//  CoLocate
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

    @IBOutlet var postcodeField: UITextField!
    @IBOutlet var continueButton: PrimaryButton!
    @IBOutlet private var scrollView: UIScrollView!
    
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
        self.view .addGestureRecognizer(UITapGestureRecognizer(target: postcodeField, action: #selector(resignFirstResponder)))
        
        notificationCenter.addObserver(self, selector: #selector(keyboardWasShown(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWasHidden(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    @IBAction func didTapContinue() {
        guard postcodeField.text?.count == 4 else {
            showAlert()
            return
        }
        
        persistence.partialPostcode = postcodeField.text
        continueHandler()
    }
    
    private func showAlert() {
        let alert = UIAlertController(title: nil, message: "To continue, enter the first four characters of your postcode.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func keyboardWasShown(_ notification: Notification) {
        guard let kbFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbFrame.size.height, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
        
        var visibleRegion = self.view.frame
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
        textField.resignFirstResponder()
        return false
    }
        
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString: String) -> Bool {
        let existingLength = textField.text?.count ?? 0
        return existingLength - range.length + replacementString.count <= maxLength
    }
}
