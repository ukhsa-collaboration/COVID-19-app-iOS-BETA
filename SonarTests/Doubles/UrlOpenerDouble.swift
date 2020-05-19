//
//  UrlOpenerDouble.swift
//  SonarTests
//
//  Created by NHSX on 5/18/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import Sonar

class UrlOpenerDouble: TestableUrlOpener {
    var urls: [URL] = []
    
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey : Any], completionHandler completion: ((Bool) -> Void)?) {
        
        urls.append(url)
    }
    

}
