//
//  TestableUrlOpener.swift
//  Sonar
//
//  Created by NHSX on 5/18/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

protocol TestableUrlOpener {
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey : Any], completionHandler completion: ((Bool) -> Void)?)
}

extension TestableUrlOpener {
    func open(_ url: URL) {
        open(url, options: [:], completionHandler: nil)
    }
}

extension UIApplication: TestableUrlOpener {
}
