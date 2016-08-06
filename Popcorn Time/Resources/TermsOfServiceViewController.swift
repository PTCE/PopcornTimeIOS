

import UIKit

class TermsOfServiceViewController: UIViewController {
    
    @IBAction func accepted(sender: UIButton) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "TOSAccepted")
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func canceled(sender: UIButton) {
        exit(0)
    }

}
