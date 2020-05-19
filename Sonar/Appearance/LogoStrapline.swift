//
//  LogoStrapline.swift
//  Sonar
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

@IBDesignable
class LogoStrapline: UIView {
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!

    var accessibilityElement: UIAccessibilityElement!

    static var nibName: String {
        String(describing: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        commonInit()
    }

    override func layoutSubviews() {
        accessibilityElement.accessibilityFrame = UIAccessibility.convertToScreenCoordinates(
            logoImageView.frame.union(titleLabel.frame),
            in: self
        )
    }

    @IBAction func infoTapped(_ sender: UIButton) {
        UIApplication.shared.open(ContentURLs.shared.info)
    }

    func commonInit() {
        guard let view = loadViewFromNib() else {
            return
        }
        
        view.backgroundColor = UIColor(named: "NHS Blue")
        titleLabel.text = "COVID-19"

        addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        accessibilityElement = UIAccessibilityElement(accessibilityContainer: self)
        accessibilityElement.accessibilityLabel = "NHS COVID-19"
        accessibilityElements = [accessibilityElement!, infoButton!]
    }
    
    func loadViewFromNib() -> UIView? {
        let nib = UINib(nibName: LogoStrapline.nibName, bundle: Bundle(for: LogoStrapline.self))
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
}
