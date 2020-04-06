//
//  UITestResponder.swift
//  CoLocateInternal
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if INTERNAL || DEBUG

enum UITestResponder {
    
    static func makeWindowForTesting() -> UIWindow? {
        guard
            let string = ProcessInfo.processInfo.environment[UITestPayload.environmentVariableName],
            let data = Data(base64Encoded: string),
            let payload = try? JSONDecoder().decode(UITestPayload.self, from: data)
            else { return nil }
        
        UIView.setAnimationsEnabled(false)
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        let router = AppRouter(window: window, screenMaker: UITestScreenMaker())
        router.route(to: payload.screen)
        window.makeKeyAndVisible()
        return window
    }
    
}

#endif
