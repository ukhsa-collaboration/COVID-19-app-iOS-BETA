//
//  LinkButton.swift
//  Sonar
//
//  Created by NHSX on 04/05/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

//@IBDesignable
class LinkButton: UIControl {

    @IBInspectable var title: String? {
        didSet { update() }
    }

    var url: URL?

    var textStyle: UIFont.TextStyle = .headline {
        didSet { update() }
    }

    private let titleLabel = UILabel()
    private let externalLinkImageView = UIImageView(image: UIImage(named: "External_Link"))

    override init(frame: CGRect) {
        super.init(frame: frame)

        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUp()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()

        setUp()
    }

    private func setUp() {
        isAccessibilityElement = true
        accessibilityTraits = .link
        accessibilityHint = "Opens in your browser"
        externalLinkImageView.adjustsImageSizeForAccessibilityContentSizeCategory = true

        backgroundColor = .clear

        let views = ["label": titleLabel, "image": externalLinkImageView]
        for view in views.values {
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        var constraints: [NSLayoutConstraint] = []
        constraints.append(contentsOf: NSLayoutConstraint.constraints(
            withVisualFormat: "|[label]-(10)-[image]-(>=0)-|",
            options: [.alignAllCenterY],
            metrics: nil,
            views: views
        ))
        constraints.append(
            contentsOf: NSLayoutConstraint.constraints(
            withVisualFormat: "V:|[label]|",
            options: [],
            metrics: nil,
            views: views
        ))
        let imageSize = externalLinkImageView.image!.size
        let aspectRatio = imageSize.height / imageSize.width
        constraints.append(externalLinkImageView.heightAnchor.constraint(equalTo: externalLinkImageView.widthAnchor, multiplier: aspectRatio))

        NSLayoutConstraint.activate(constraints)

        addTarget(self, action: #selector(didTap), for: .touchUpInside)

        update()
    }

    @objc func didTap() {
        guard let url = url else { return }

        UIApplication.shared.open(url)
    }

    private func update() {
        guard let title = title else { return }

        accessibilityLabel = title
        titleLabel.attributedText = NSAttributedString(
            string: title,
            attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .font: UIFont.preferredFont(forTextStyle: textStyle)
            ]
        )
    }

}
