//
//  IBView.swift
//  Sonar
//
//  Created by NHSX on 26/5/2020
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

@IBDesignable
class IBView: UIView {

    @IBOutlet weak var view: UIView!
    var icSize: CGSize!
    override init(frame: CGRect) {
        // 1. setup any properties here
        // 2. call super.init(frame:)
        super.init(frame: frame)
        // 3. Setup view from .xib file
        xibSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        // 1. setup any properties here
        // 2. call super.init(coder:)
        super.init(coder: aDecoder)
        // 3. Setup view from .xib file

        xibSetup()
    }

    func xibSetup() {
        view = loadViewFromNib()
        // use bounds not frame or it'll be offset
        view.frame = bounds
        icSize = bounds.size

        // Adding custom subview on top of our view (over any custom drawing > see note below)
        addSubview(view)

        // Make the view stretch with containing view
        view.translatesAutoresizingMaskIntoConstraints = false

        view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        view.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)

        // Assumes UIView is top level and only object in CustomView.xib file
        let view = (nib.instantiate(withOwner: self, options: nil)[0] as? UIView)!
        return view
    }

    override var intrinsicContentSize: CGSize {
        return icSize
    }
}
