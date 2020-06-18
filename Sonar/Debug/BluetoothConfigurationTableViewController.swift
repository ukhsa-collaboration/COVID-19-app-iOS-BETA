//
//  BluetoothConfigurationTableViewController.swift
//  Sonar
//
//  Created by NHSX on 10.06.20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class BluetoothConfigurationTableViewController: UITableViewController {
        
    lazy var listener: BTLEListener = (UIApplication.shared.delegate as! AppDelegate).bluetoothNursery.listener as! BTLEListener
    
    @IBAction func didChangeValue(_ sender: UIStepper) {
        listener.restartAdvertisingInterval = sender.value
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch (indexPath.row, indexPath.section) {
        case (0, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StepperTableViewCell.self), for: indexPath) as! StepperTableViewCell

            cell.stepper.value = listener.restartAdvertisingInterval
            cell.stepperLabel?.text = "Restart advertising (\(Int(cell.stepper.value))s)"
            return cell
            
        default:
            preconditionFailure()

        }
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
