//
//  UITestScreenMaker.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if INTERNAL || DEBUG

struct UITestScreenMaker: ScreenMaking {
    
    func makeViewController(for screen: Screen) -> UIViewController {
        switch screen {
        case .potential:
            let viewController = UIViewController()
            viewController.title = "Potential"
            return UINavigationController(rootViewController: viewController)
        case .onboarding:
            return OnboardingViewController.instantiate { viewController in
                let environment = OnboardingEnvironment(mockWithHost: viewController)
                viewController.environment = environment
                viewController.didComplete = { [weak viewController] in
                    let summary = StateSummaryViewController(environment: environment)
                    viewController?.present(summary, animated: false, completion: nil)
                }
                
                // TODO: Remove this – currently needed to kick `updateState()`
                viewController.rootViewController = nil
            }
        }
    }
    
}

private extension OnboardingEnvironment {
    
    convenience init(mockWithHost host: UIViewController) {
        // TODO: Fix initial state of mocks.
        // Currently it’s set so that onboarding is “done” as soon as we allow data sharing – so we can have a minimal
        // UI test.
        self.init(
            persistence: InMemoryPersistence(),
            authorizationManager: EphemeralAuthorizationManager()
        )
    }
    
}

private class InMemoryPersistence: Persisting {
    
    var allowedDataSharing = false
    var registration: Registration? = Registration(id: UUID(), secretKey: Data())
    var diagnosis = Diagnosis.unknown

}

private class EphemeralAuthorizationManager: AuthorizationManaging {
    var bluetooth: AuthorizationStatus = .allowed
    func notifications(completion: @escaping (AuthorizationStatus) -> Void) {
        completion(.allowed)
    }
}

private class StateSummaryViewController: UITableViewController {
    private let cellID = UUID().uuidString
    private let environment: OnboardingEnvironment
    
    init(environment: OnboardingEnvironment) {
        self.environment = environment
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(InfoTableViewCell.self, forCellReuseIdentifier: cellID)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        cell.textLabel?.text = "Allowed Data Sharing"
        cell.detailTextLabel?.text = environment.persistence.allowedDataSharing ? "Yes" : "No"
        cell.accessibilityLabel = cell.textLabel?.text
        cell.accessibilityValue = cell.detailTextLabel?.text
        return cell
    }
}

private class InfoTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
