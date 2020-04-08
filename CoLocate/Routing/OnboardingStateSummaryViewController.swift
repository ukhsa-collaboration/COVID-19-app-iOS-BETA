//
//  OnboardingSummaryViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

#if INTERNAL || DEBUG

import UIKit

class OnboardingStateSummaryViewController: UITableViewController {
    private let cellID = UUID().uuidString
    private let rows: [InfoRow]
    
    init(environment: OnboardingEnvironment) {
        rows = [
            InfoRow(label: "Allowed Data Sharing", value: environment.persistence.allowedDataSharing),
            InfoRow(label: "Bluetooth State", value: environment.authorizationManager.bluetooth.name),
        ]
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
        rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let row = rows[indexPath.row]
        cell.textLabel?.text = row.label
        cell.detailTextLabel?.text = row.value
        cell.accessibilityLabel = row.label
        cell.accessibilityValue = row.value
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

private struct InfoRow {
    var label: String
    var value: String
}

private extension InfoRow {
    
    init(label: String, value: Bool) {
        self.init(
            label: label,
            value: value ? "Yes" : "No"
        )
    }
}

private extension AuthorizationStatus {
    var name: String {
        switch self {
        case .notDetermined:
            return "Not determined"
        case .denied:
            return "Denied"
        case .allowed:
            return "Allowed"
        }
    }
}

#endif
