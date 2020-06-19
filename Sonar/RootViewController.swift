//
//  RootViewController.swift
//  Sonar
//
//  Created by NHSX on 19/06/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    var logoStrapline: UIView {
        let logoView = UIImageView(image: UIImage(named: "NHS_Logo"))
        logoView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = false
        label.font = UIFont.boldSystemFont(ofSize: 17.0)
        label.text = "COVID-19"
        label.textColor = UIColor.nhs.blue
        
        // Hack to left-align the content of the stackview.
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let stack = UIStackView(arrangedSubviews: [logoView, label, spacerView])
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 16
        stack.accessibilityLabel = label.text
        
        if #available(iOS 13.0, *) {
            stack.showsLargeContentViewer = true
            stack.largeContentImage = UIImage(named: "NHS-Logo-Template")
            stack.largeContentTitle = "COVID-19"
            stack.addInteraction(UILargeContentViewerInteraction())
        }
        
        return stack
    }
    
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 20, bottom: 20, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = 20
        return stackView
    }()
    
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    let screenImage: UIImageView = {
        let screenImage = UIImageView(image: UIImage(named: "Onboarding_protect"))
        screenImage.contentMode = .scaleAspectFit
        return screenImage
    }()
    
    let titleLabel: UILabel = UILabel(textStyle: .largeTitle, text: "This app is no longer in use")
    
    let trialOverText = UILabel(textStyle: .body, text: "The Isle of Wight trial is now complete and the app is no longer operational. Please uninstall the app. Thank you for participating in the trial and playing a vital role in supporting the NHS.")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.nhs.grey.five
        
        let safeArea = view.safeAreaLayoutGuide
        let contentLayoutGuide = scrollView.contentLayoutGuide
        
        stackView.addArrangedSubview(logoStrapline)
        stackView.addArrangedSubview(screenImage)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(trialOverText)

        scrollView.addSubview(stackView)
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
}

extension UILabel {
    convenience init(textStyle: UIFont.TextStyle, text: String) {
        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        self.text = text
        font = UIFont.preferredFont(forTextStyle: textStyle)
        textColor = UIColor.nhs.text
        numberOfLines = 0
    }
}
