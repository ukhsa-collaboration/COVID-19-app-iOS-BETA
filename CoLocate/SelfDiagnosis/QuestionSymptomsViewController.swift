//
//  QuestionSymptomsViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class QuestionSymptomsViewController: UIViewController, Storyboarded {
    static var storyboardName = "SelfDiagnosis"
    
    @IBOutlet weak var pageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var yesButton: AnswerButton!
    @IBOutlet weak var noButton: AnswerButton!
    @IBOutlet weak var questionButton: PrimaryButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var buttonAction: ((Bool) -> Void)!
    var questionState: Bool?
    
    func inject(
        pageNumber: Int,
        pageCount: Int,
        questionTitle: String,
        questionDetail: String,
        questionError: String,
        questionYes: String,
        questionNo: String,
        buttonText: String,
        buttonAction: @escaping (Bool) -> Void
    ) {        
        pageLabel.text = "\(pageNumber)/\(pageCount)"
        titleLabel.text = questionTitle
        detailLabel.text = questionDetail
        errorLabel.text = questionError
        yesButton.text = questionYes
        noButton.text = questionNo
        questionButton.titleLabel?.text = buttonText
        
        self.buttonAction = buttonAction
    }
    
    @IBAction func yesTapped(_ sender: Any) {
        yesButton.isSelected = true
        noButton.isSelected = false
        questionState = true
        scrollView.scrollRectToVisible(questionButton.frame, animated: true)
    }
    
    @IBAction func noTapped(_ sender: Any) {
        yesButton.isSelected = false
        noButton.isSelected = true
        questionState = false
        scrollView.scrollRectToVisible(questionButton.frame, animated: true)
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        guard let state = questionState else {
            errorLabel.isHidden = false
            return
        }
        buttonAction(state)
    }
    
}
