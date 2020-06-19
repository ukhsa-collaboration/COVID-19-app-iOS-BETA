//
// Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

public class LinkButton: UIControl {
    
    private var title: String
    private var accessoryImage: UIImage?
    
    public required init(title: String, accessoryImage: UIImage? = UIImage(named: "External_Link")) {
        self.title = title
        self.accessoryImage = accessoryImage
        super.init(frame: .zero)
        
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUp() {
        isAccessibilityElement = true
        accessibilityTraits = .link
        accessibilityHint = "Opens in your browser"
        accessibilityLabel = title
        
        backgroundColor = .clear
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textColor = UIColor.nhs.link
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
        titleLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .horizontal)

        let externalLinkImageView = accessoryImage.map { (image: UIImage) -> UIImageView in
            let imageView = UIImageView(image: image)
            imageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
            imageView.contentMode = .scaleAspectFit
            
            let imageSize = image.size
            let aspectRatio = imageSize.height / imageSize.width
            imageView.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .horizontal)
            
            NSLayoutConstraint.activate([
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: aspectRatio),
            ])
            
            return imageView
        }
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, externalLinkImageView, UIView()].compactMap { $0 })
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 10
        stackView.isUserInteractionEnabled = false
        
        addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 45),
        ])
    }
}
