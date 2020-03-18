//
//  TableViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

class EnterDiagnosisTableViewController: UITableViewController {
    
    var diagnosisService: DiagnosisService = DiagnosisService()
    
    enum Rows: Int {
        case title, yes, no
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Diagnosis"
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case Rows.title.rawValue:
            break
            
        case Rows.yes.rawValue:
            diagnosisService.recordDiagnosis(.infected)
            
        case Rows.no.rawValue:
            diagnosisService.recordDiagnosis(.notInfected)
            
        default:
            print("\(#file).\(#function) unknown indexPath selected: \(indexPath)")
        }
    }
    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
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
