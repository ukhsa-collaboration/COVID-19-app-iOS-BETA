//
//  DrawerMailboxingDouble.swift
//  SonarTests
//
//  Created by NHSX on 5/27/20
//  Copyright © 2020 NHSX. All rights reserved.
//

@testable import Sonar

class DrawerMailboxingDouble: DrawerMailboxing {
    var messages: [DrawerMessage] = []

    func receive() -> DrawerMessage? {
        guard !messages.isEmpty else { return nil }

        return messages.removeFirst()
    }

    func post(_ message: DrawerMessage) {
        messages.append(message)
    }
}
