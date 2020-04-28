//
//  AppRouter.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import UIKit

protocol ScreenMaking {
    func makeViewController(for screen: Screen) -> UIViewController
}

class AppRouter {
    
    private let window: UIWindow
    private let screenMaker: ScreenMaking
    
    init(window: UIWindow, screenMaker: ScreenMaking) {
        self.window = window
        self.screenMaker = screenMaker
    }
    
    func route(to screen: Screen) {
        window.rootViewController = screenMaker.makeViewController(for: screen)
    }
        
}
