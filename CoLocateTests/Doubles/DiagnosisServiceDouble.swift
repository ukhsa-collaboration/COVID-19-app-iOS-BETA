//
//  DiagnosisServiceDouble.swift
//  CoLocateTests
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
@testable import CoLocate

class DiagnosisServiceDouble: DiagnosisService {
    private var _currentDiagnosis = Diagnosis.unknown
    override var currentDiagnosis: Diagnosis {
        get { _currentDiagnosis }
        set { _currentDiagnosis = newValue }
    }
    
    override func recordDiagnosis(_ diagnosis: Diagnosis) {
    }
}
