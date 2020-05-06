//
//  LiveBluetoothDebuggerTableViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if DEBUG || INTERNAL

final class LiveBTLEDebuggerTableViewController: UITableViewController {

    var persistence: Persisting = (UIApplication.shared.delegate as! AppDelegate).persistence
    
    var broadcastIdGenerator: BroadcastPayloadGenerator? = ((UIApplication.shared.delegate as! AppDelegate).bluetoothNursery as! ConcreteBluetoothNursery).broadcastIdGenerator
    
    @objc var repository: PersistingContactEventRepository = (UIApplication.shared.delegate as! AppDelegate).bluetoothNursery.contactEventRepository as! PersistingContactEventRepository
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        repository.delegate = self
    }

}

// MARK: - UITableViewDataSource
extension LiveBTLEDebuggerTableViewController {
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
        case Sections.myEncryptedBroadcastId.rawValue: return "My Encrypted Broadcast ID"
        case Sections.visibleDevices.rawValue: return "Visible Devices"
        default: preconditionFailure("No section \(section)")

        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {

        case Sections.mySonarId.rawValue: return 1
        case Sections.myEncryptedBroadcastId.rawValue: return 1
        case Sections.visibleDevices.rawValue: return repository.contactEvents.count
        default: preconditionFailure("No section \(section)")

        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: DebuggerTableViewCell.self),
            for: indexPath
        ) as! DebuggerTableViewCell

        switch (indexPath.section, indexPath.row) {

        case (Sections.mySonarId.rawValue, _):
            let sonarId = persistence.registration?.id.uuidString ?? "<not yet registered>"
            cell.textLabel?.text = sonarId
            cell.gradientColorData = sonarId.data(using: .utf8)
            
        case (Sections.myEncryptedBroadcastId.rawValue, _):
            cell.textLabel?.text = broadcastIdGenerator?.broadcastPayload()?.cryptogram.base64EncodedString()
            cell.gradientColorData = broadcastIdGenerator?.broadcastPayload()?.cryptogram

            // TODO: This is going to be broken until we chase the BroadcastPayload back up through
        case (Sections.visibleDevices.rawValue, let row):
            cell.textLabel?.text = repository.contactEvents[row].encryptedRemoteContactId?.base64EncodedString()
            cell.gradientColorData = repository.contactEvents[row].encryptedRemoteContactId
            
        default:
            preconditionFailure("No cell at indexPath \(indexPath)")

        }

        return cell
    }

}

// MARK: - ContactEventRepositoryDelegate
extension LiveBTLEDebuggerTableViewController: ContactEventRepositoryDelegate {

    func repository(_ repository: ContactEventRepository, didRecord broadcastPayload: IncomingBroadcastPayload, for peripheral: BTLEPeripheral) {
        tableView.reloadData()
    }

    // TODO: [dlb] Can we delete this method if it is not being used? Or should this also reload the table view?
    func repository(_ repository: ContactEventRepository, didRecordRSSI RSSI: Int, for peripheral: BTLEPeripheral) {

    }

    // TODO: [dlb] If we need the above 'didRecordRSSI:' method, should we also have a method for when the TxPower is read?
}

#endif
