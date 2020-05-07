//
//  ContactEventDetailTableViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class ContactEventDetailTableViewController: UITableViewController {
    
    var contactEvent: ContactEvent! = nil
    
    lazy var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .default
        return formatter
    }()
    
    enum Sections: Int, CaseIterable {
        case timestamps, duration, countryCode, broadcastId, hmac, txPower, rssi
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Sections(rawValue: section) {
        case .timestamps: return 2
        case .duration: return 1
        case .countryCode: return 1
        case .broadcastId: return 1
        case .hmac: return 1
        case .txPower: return 2
        case .rssi: return contactEvent.rssiValues.count
        default: fatalError("missing case")
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Sections(rawValue: section) {
        case .timestamps: return "Timestamps"
        case .duration: return "Duration"
        case .countryCode: return "Country Code"
        case .broadcastId: return "Broadcast Id"
        case .hmac: return "HMAC"
        case .txPower: return "Tx Power"
        case .rssi: return "RSSI values"
        default: fatalError("missing case")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        let section = Sections(rawValue: indexPath.section)
        switch (section, indexPath.row) {
            
        case (.timestamps, 0):
            if let timestamp = contactEvent.broadcastPayload?.transmissionTime {
                cell.textLabel?.text = "Tx: \(Date(timeIntervalSince1970: Double(timestamp)))"
            } else {
                cell.textLabel?.text = "Tx: --"
            }

        case (.timestamps, 1):
            cell.textLabel?.text = "Rx: \(contactEvent.timestamp)"

        case (.duration, _):
            cell.textLabel?.text = durationFormatter.string(from: contactEvent.duration)
            
        case (.countryCode, _):
            cell.textLabel?.text = "\(contactEvent.broadcastPayload?.countryCode ??? "--")"
            
        case (.broadcastId, _):
            let broadcastId = contactEvent.encryptedRemoteContactId?.base64EncodedString(options: .lineLength64Characters) ?? "--"
            cell.textLabel?.text = "\(broadcastId)"

        case (.hmac, _):
            let hmac = contactEvent.broadcastPayload?.hmac.base64EncodedString(options: .lineLength64Characters) ?? "--"
            cell.textLabel?.text = "\(hmac)"

        case (.txPower, 0):
            cell.textLabel?.text = "Advertisement: \(contactEvent.txPower)"
            
        case (.txPower, 1):
            cell.textLabel?.text = "Self-reported: \(contactEvent.broadcastPayload?.txPower ??? "--")"
            
        case (.rssi, let row):
            cell.textLabel?.text = String(format: "%d (%.2f)", contactEvent.rssiValues[row], contactEvent.rssiIntervals[row])
            
        default: fatalError("missing case")
        }

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
