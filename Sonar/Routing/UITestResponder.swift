//
//  UITestResponder.swift
//  SonarInternal
//
//  Created by NHSX on 03/04/2020.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if DEBUG

struct UITestResponder {
    private let uiTestScreenMaker = UITestScreenMaker()
    private var payload: UITestPayload

    init?() {
        guard
            let string = ProcessInfo.processInfo.environment[UITestPayload.environmentVariableName],
            let data = Data(base64Encoded: string),
            let payload = try? JSONDecoder().decode(UITestPayload.self, from: data)
            else { return nil }

        self.payload = payload
    }

    func makeWindowForTesting() -> UIWindow {
        UIView.setAnimationsEnabled(false)
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = uiTestScreenMaker.makeViewController(for: payload.screen)
        window.makeKeyAndVisible()
        return window
    }

    func resetTime() {
        uiTestScreenMaker.resetTime()
    }

    func advanceTime(_ timeInterval: TimeInterval) {
        uiTestScreenMaker.advanceTime(timeInterval)
    }
}

#endif
