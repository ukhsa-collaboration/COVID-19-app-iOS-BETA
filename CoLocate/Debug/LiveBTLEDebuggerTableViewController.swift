//
//  LiveBluetoothDebuggerTableViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class LiveBTLEDebuggerTableViewController: UITableViewController {

    var persistence: Persistence = Persistence.shared
    
    @objc var collector: ContactEventCollector = (UIApplication.shared.delegate as! AppDelegate).bluetoothNursery.contactEventCollector
    
    var observation: NSKeyValueObservation?
    
    var sonarIds: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        observation = observe(\.collector._contactEventCount) { object, change in
            DispatchQueue.main.async {
                self.sonarIds = self.collector.contactEvents.compactMap({ $0.value.sonarId.base64EncodedString() })
                self.tableView.reloadData()
            }
        }
        
        sonarIds = Array(collector.contactEvents.values.compactMap({ $0.sonarId.base64EncodedString() }))
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "My Device"
        case 1: return "Visible Devices"
        default: preconditionFailure("No section \(section)")
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return sonarIds.count
            
        default:
            preconditionFailure("No section \(section)")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as! DebuggerTableViewCell

        switch (indexPath.section, indexPath.row) {
            
        case (0, _):
            cell.textLabel?.text = persistence.registration?.id.uuidString
            cell.base64Data = persistence.registration!.id.uuidString.data(using: .utf8)
            
        case (1, let row):
            cell.textLabel?.text = sonarIds[row]
            cell.base64Data = sonarIds[row].data(using: .utf8)
            
        default:
            preconditionFailure("No cell at indexPath \(indexPath)")
        }

        return cell
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension Data {
    func asCGColor(alpha: CGFloat) -> CGColor {
        return asUIColor(alpha: alpha).cgColor
    }

    func asUIColor(alpha: CGFloat) -> UIColor {
        return UIColor(red: CGFloat(self[0]) / 255.0, green: CGFloat(self[1]) / 255.0, blue: CGFloat(self[2]) / 255.0, alpha: alpha)
    }
}
