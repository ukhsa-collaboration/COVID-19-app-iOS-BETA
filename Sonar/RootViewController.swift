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
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            logoStrapline,
            screenImage,
            titleLabel,
            trialOverText,
            iFeelUnwellButton,
            howToUninstallButton,
            aboutTheAppButton
        ])
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
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
    
    let titleLabel: UILabel = UILabel(accessibilityTraits: .header, textStyle: .largeTitle, text: "This app is no longer in use")
    
    let trialOverText = UILabel(textStyle: .body, text: "The Isle of Wight trial is now complete and the app is no longer operational. Please uninstall the app. Thank you for participating in the trial and playing a vital role in supporting the NHS.")
    
    let iFeelUnwellButton = LinkButton(title: "I feel unwell")
    
    let howToUninstallButton = LinkButton(title: "How to uninstall the app")
    
    let aboutTheAppButton = LinkButton(title: "About the app")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.nhs.grey.five
        
        let safeArea = view.safeAreaLayoutGuide
        let contentLayoutGuide = scrollView.contentLayoutGuide

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
        
        iFeelUnwellButton.addTarget(self, action: #selector(iFeelUnwellButtonTapped), for: .touchUpInside)
        howToUninstallButton.addTarget(self, action: #selector(howToUninstallButtonTapped), for: .touchUpInside)
        aboutTheAppButton.addTarget(self, action: #selector(aboutTheAppButtonTapped), for: .touchUpInside)
    }
    
    @objc private func iFeelUnwellButtonTapped() {
        URL(string: "https://faq.covid19.nhs.uk/article/KA-01078/en-us").map { UIApplication.shared.open($0) }
    }
    
    @objc private func howToUninstallButtonTapped() {
        URL(string: "https://faq.covid19.nhs.uk/article/KA-01098/en-us").map { UIApplication.shared.open($0) }
    }
    
    @objc private func aboutTheAppButtonTapped() {
        URL(string: "https://faq.covid19.nhs.uk/article/KA-01097/en-us").map { UIApplication.shared.open($0) }
    }
}

extension UILabel {
    convenience init(accessibilityTraits: UIAccessibilityTraits = [], textStyle: UIFont.TextStyle, text: String) {
        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        self.text = text
        font = UIFont.preferredFont(forTextStyle: textStyle)
        textColor = UIColor.nhs.text
        numberOfLines = 0
        adjustsFontForContentSizeCategory = true
        self.accessibilityTraits = accessibilityTraits
    }
}
