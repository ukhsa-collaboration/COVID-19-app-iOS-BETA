//
//  LiveBluetoothDebuggerTableViewController.swift
//  Sonar
//
//  Created by NHSX on 01.04.20.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if DEBUG || INTERNAL

final class ContactEventsTableViewController: UITableViewController, ContactEventRepositoryDelegate {

    var persistence: Persisting = (UIApplication.shared.delegate as! AppDelegate).persistence
    
    var broadcastIdGenerator: BroadcastPayloadGenerator? = ((UIApplication.shared.delegate as! AppDelegate).bluetoothNursery as! ConcreteBluetoothNursery).broadcastIdGenerator
    
    var repository: PersistingContactEventRepository = (UIApplication.shared.delegate as! AppDelegate).bluetoothNursery.contactEventRepository as! PersistingContactEventRepository
    
    var items: [ContactEvent] {
        repository.contactEvents.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        repository.delegate = self
    }
    
    // MARK: - ContactEventRepositoryDelegate
    
    func repository(_ repository: ContactEventRepository, didRecord broadcastPayload: IncomingBroadcastPayload, for peripheral: Peripheral) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func repository(_ repository: ContactEventRepository, didRecordRSSI RSSI: Int, for peripheral: Peripheral) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // MARK: - UITableViewDataSource

    private enum Sections: Int, CaseIterable {
        case mySonarId
        case myEncryptedBroadcastId
        case visibleDevices
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {

        case Sections.mySonarId.rawValue: return "My Sonar ID"
        case Sections.myEncryptedBroadcastId.rawValue: return "My Broadcast ID"
        case Sections.visibleDevices.rawValue: return "Contact Events"
        default: preconditionFailure("No section \(section)")

        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {

        case Sections.mySonarId.rawValue: return 1
        case Sections.myEncryptedBroadcastId.rawValue: return 1
        case Sections.visibleDevices.rawValue: return items.count
        default: preconditionFailure("No section \(section)")

        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: GradientBackgroundTableViewCell.self),
            for: indexPath
        ) as! GradientBackgroundTableViewCell
        cell.textLabel?.backgroundColor = .clear
        cell.detailTextLabel?.backgroundColor = .clear
        
        switch (indexPath.section, indexPath.row) {

        case (Sections.mySonarId.rawValue, _):
            
            let sonarId = persistence.registration?.sonarId.uuidString ?? "Not registered"
            cell.textLabel?.text = sonarId
            cell.detailTextLabel?.text = nil
            cell.gradientColorData = Data()
            
        case (Sections.myEncryptedBroadcastId.rawValue, _):
            cell.accessoryType = .none
            cell.textLabel?.text = broadcastIdGenerator?.broadcastPayload()?.cryptogram.base64EncodedString()
            cell.detailTextLabel?.text = nil
            cell.gradientColorData = broadcastIdGenerator?.broadcastPayload()?.cryptogram

        case (Sections.visibleDevices.rawValue, let row):
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = items[row].encryptedRemoteContactId?.base64EncodedString()
            cell.detailTextLabel?.text = items[row].rssiValues.suffix(16).map({"\($0)"}).joined(separator: ", ")
            cell.gradientColorData = items[row].encryptedRemoteContactId
            
        default:
            preconditionFailure("No cell at indexPath \(indexPath)")

        }

        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
            
        case "contactEventDetail":
            let indexPath = tableView.indexPath(for: sender as! UITableViewCell)!
            (segue.destination as! ContactEventDetailTableViewController).contactEvent = items[indexPath.row]

        default:
            break
        }
    }

}

#endif
