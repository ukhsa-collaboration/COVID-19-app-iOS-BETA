//
//  LinkingIdManagerDouble.swift
//  SonarTests
//
//  Created by NHSX on 5/14/20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
@testable import Sonar

class LinkingIdManagerDouble: LinkingIdManaging {
    var fetchCompletion: ((LinkingId?, String?) -> Void)?
    func fetchLinkingId(completion: @escaping (LinkingId?, String?) -> Void = { _, _ in }) {
        fetchCompletion = completion
    }
}
