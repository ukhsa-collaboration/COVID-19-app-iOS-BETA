//
//  Persisting.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

enum Diagnosis: Int, CaseIterable {
    case notInfected = 1, infected, potential
}

protocol Persisting {
    var allowedDataSharing: Bool { get nonmutating set }
    var registration: Registration? { get nonmutating set }
    var diagnosis: Diagnosis? { get nonmutating set }
    var enableNewSelfDiagnosis: Bool { get nonmutating set }
    var partialPostcode: String? { get nonmutating set }
    
    func clear()
}
