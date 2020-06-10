//
//  Tryable.swift
//  RegistrationCanary
//
//  Created by NHSX on 6/10/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

protocol Attemptable {
    var delgate: TryableDelegate? { get set }
    
    func attempt()
}

protocol TryableDelegate {
    
}
