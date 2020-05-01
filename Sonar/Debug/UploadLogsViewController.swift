//
//  UploadLogsViewController.swift
//  Sonar
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if DEBUG || INTERNAL

class UploadLogsViewController: UITableViewController {

    let persistence = (UIApplication.shared.delegate as! AppDelegate).persistence


    var uploadLog: [UploadLog] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        uploadLog = persistence.uploadLog.reversed()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uploadLog.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = String(describing: uploadLog[indexPath.row])

        return cell
    }

    @IBAction func refresh(_ sender: UIBarButtonItem) {
        uploadLog = persistence.uploadLog.reversed()
    }

}

#endif
