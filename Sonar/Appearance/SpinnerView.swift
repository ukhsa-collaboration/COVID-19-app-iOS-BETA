//
//  SpinnerView.swift
//  Sonar
//
//  Created by NHSX on 5/4/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import QuartzCore

class SpinnerView: AutoscalingImageView {

    override var isHidden: Bool {
        didSet {
            if isHidden {
                layer.removeAnimation(forKey: "rotationAnimation")
            } else {
                layer.add(rotation, forKey: "rotationAnimation")
            }
        }
    }

    lazy var rotation: CABasicAnimation = {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = Double.pi * 2
        rotation.duration = 0.75
        rotation.isCumulative = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        return rotation
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in
            if !self.isHidden {
                self.layer.add(self.rotation, forKey: "rotationAnimation")
            }
        }
    }
}
