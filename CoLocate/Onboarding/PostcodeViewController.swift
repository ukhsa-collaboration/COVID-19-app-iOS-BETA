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
    
    @IBOutlet var postcodeField: UITextField!
    @IBOutlet var continueButton: PrimaryButton!
    
    func inject(persistence: Persisting) {
        self.persistence = persistence
    }
    
    override func viewDidLoad() {
        postcodeField.addTarget(self, action:#selector(updateContinueButton), for: .editingChanged)
        updateContinueButton()
    }
    
    @IBAction func didTapContinue() {
        guard postcodeField.text?.count == 4 else { return }
        
        persistence.partialPostcode = postcodeField.text
        performSegue(withIdentifier: "unwindFromPostcode", sender: self)
    }
    
    @objc func updateContinueButton() {
        continueButton.isEnabled = postcodeField.text?.count == maxLength
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
