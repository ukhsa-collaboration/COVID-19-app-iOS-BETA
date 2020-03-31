//
//  PersistanceDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import CoLocate

class PersistanceDouble: Persistance {

    private var _diagnosis = Diagnosis.unknown
    override var diagnosis: Diagnosis {
        get { _diagnosis }
        set { _diagnosis = newValue }
    }
    
}
