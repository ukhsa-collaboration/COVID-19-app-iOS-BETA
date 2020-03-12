import UIKit

class SelfReportingViewController: UIViewController {
  @IBOutlet var titleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

      titleLabel.text = "Have you been diagnosed with coronavirus?"
    }
}
