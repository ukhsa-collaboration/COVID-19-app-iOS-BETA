//
//  LogoStrapline.swift
//  CoLocate
//
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

@IBDesignable
class LogoStrapline: UIView {
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var titleLabel: UILabel!
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 64.0)
    }
    
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
    
    func commonInit() {
        guard let view = loadViewFromNib() else {
            return
        }
        
        view.backgroundColor = UIColor(named: "NHS Blue")
        titleLabel.textColor = UIColor(named: "NHS White")
        titleLabel.text = "Coronavirus tracing"
        
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    func loadViewFromNib() -> UIView? {
        let nib = UINib(nibName: LogoStrapline.nibName, bundle: Bundle(for: LogoStrapline.self))
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
}
