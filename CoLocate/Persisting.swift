//
//  Persisting.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum Diagnosis: Int, CaseIterable {
    case unknown, notInfected, infected, potential
}

protocol Persisting {
    var allowedDataSharing: Bool { get nonmutating set }
    var registration: Registration? { get nonmutating set }
    var diagnosis: Diagnosis { get nonmutating set }
}
