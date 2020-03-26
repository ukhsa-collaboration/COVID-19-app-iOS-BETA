//
//  UIViewController+Storyboarded.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

enum Storyboard: String {
    case okNow = "OkNow"
    case permissions = "Permissions"
    case enterDiagnosis = "EnterDiagnosis"
    case pleaseSelfIsolate = "PleaseSelfIsolate"
    case potential = "Potential"
    case registration = "Registration"
}

protocol Storyboarded: class {
    var coordinator: AppCoordinator? { get set }
    static func instantiate(storyboard: Storyboard) -> Self
}

extension Storyboarded where Self: UIViewController {
    static func instantiate(storyboard: Storyboard = .okNow) -> Self {
   
        let fullName = NSStringFromClass(self)
        let className = fullName.components(separatedBy: ".")[1]
        let storyboard = UIStoryboard(name: storyboard.rawValue, bundle: Bundle.main)
        return storyboard.instantiateViewController(withIdentifier: className) as! Self
    }
}

