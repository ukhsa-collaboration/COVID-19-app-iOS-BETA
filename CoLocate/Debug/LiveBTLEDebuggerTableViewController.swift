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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 0
            
        default:
            preconditionFailure("No section \(section)")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        switch (indexPath.section, indexPath.row) {
        case (0, _):
            cell.textLabel?.text = persistence.registration?.id.uuidString
            let layer = CAGradientLayer()
            layer.frame = cell.bounds
            layer.startPoint = CGPoint(x: 0, y: 0)
            layer.endPoint = CGPoint(x: 1, y: 0)
            layer.colors = [
                persistence.registration?.id.asCGColor(alpha: 0) as Any,
                persistence.registration?.id.asCGColor(alpha: 1) as Any
            ]
            cell.contentView.layer.insertSublayer(layer, at: 0)
            
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

extension UUID {
    func asCGColor(alpha: CGFloat) -> CGColor {
        return asUIColor(alpha: alpha).cgColor
    }
    func asUIColor(alpha: CGFloat) -> UIColor {
        return UIColor(red: CGFloat(uuid.0) / 255.0, green: CGFloat(uuid.1) / 255.0, blue: CGFloat(uuid.2) / 255.0, alpha: alpha)
    }
}
