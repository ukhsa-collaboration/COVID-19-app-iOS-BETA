//
//  AnswerButton.swift
//  Sonar
//
//  Created by NHSX on 4/8/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

@IBDesignable
class AnswerButton: UIControl, UpdatesBasedOnAccessibilityDisplayChanges {

    @IBInspectable var text: String? {
        didSet {
            textLabel.text = text
            accessibilityLabel = textLabel.accessibilityLabel
        }
    }

    let textLabel = UILabel()
    let imageView = UIImageView()
    private var imageWidthConstraint: NSLayoutConstraint!

    override var isSelected: Bool {
        didSet {
            if isSelected {
                accessibilityTraits.insert(.selected)
            } else {
                accessibilityTraits.remove(.selected)
            }

            layer.borderWidth = isSelected ? 2 : 0
            layer.borderColor = UIColor(named: "NHS Highlight")!.cgColor
            imageView.isHighlighted = isSelected
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 100)
    }

    override func awakeFromNib() {
        accessibilityTraits = [.button]
        isAccessibilityElement = true
        if #available(iOS 13.0, *) {
            accessibilityRespondsToUserInteraction = true
        } else {
            // Fallback on earlier versions
        }

        layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        layer.cornerRadius = 8

        textLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        textLabel.textColor = UIColor(named: "NHS Text")!

        imageView.image = UIImage(named: "Controls_RadioButton_Unselected")
        imageView.highlightedImage = UIImage(named: "Controls_RadioButton_Selected")
        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 24)
        imageWidthConstraint.identifier = "ImageWidth"
        NSLayoutConstraint.activate([
             imageWidthConstraint,
             imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])

        let stack = UIStackView(arrangedSubviews: [
            textLabel,
            imageView,
        ])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 20

        addSubview(stack)
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            stack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stack.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            stack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])
        textLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        
        resizeImage()
    }
    
    func updateBasedOnAccessibilityDisplayChanges() {
        resizeImage()
    }
    
    private func resizeImage() {
        let scaleFactor = textLabel.font.pointSize / defaultFontSize
        imageWidthConstraint.constant = defaultImageSize * scaleFactor
    }

}

fileprivate let defaultFontSize = CGFloat(17.0)
fileprivate let defaultImageSize = CGFloat(24.0)
