

import UIKit
import JGProgressHUD
import KMPlaceholderTextView
import Alamofire
import SwiftyJSON
import OnePasswordExtension

class BugReportTableViewController: UITableViewController, JGProgressHUDDelegate {
    
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var titleField: UITextField!
    @IBOutlet var descriptionField: KMPlaceholderTextView!
    @IBOutlet var onePasswordSignInButton: UIButton?
    
    @IBAction func findLoginFrom1Password(sender: UIButton) {
        OnePasswordExtension.sharedExtension().findLoginForURLString("https://github.com", forViewController: self, sender: sender) { (loginDictionary, error) in
            if let loginDictionary = loginDictionary where !loginDictionary.isEmpty {
                self.usernameField.text = (loginDictionary[AppExtensionUsernameKey as NSObject] as! String)
                self.passwordField.text = (loginDictionary[AppExtensionPasswordKey as NSObject] as! String)
            }
        }
    }
    
    @IBAction func sendReport(sender: UIBarButtonItem) {
        guard (titleField.text?.isEmpty)! || (usernameField.text?.isEmpty)! || (passwordField.text?.isEmpty)! || descriptionField.text.isEmpty else {
            let HUD = JGProgressHUD(style: .ExtraLight)
            HUD.textLabel.text = "Loading"
            HUD.delegate = self
            HUD.showInView(view)
            Alamofire.request(.POST, "https://api.github.com/repos/PopcornTimeTV/PopcornTimeiOS/issues", parameters: ["assignee": usernameField.text!, "body": descriptionField.text, "title": titleField.text!], encoding: .JSON).authenticate(user: usernameField.text!, password: passwordField.text!).validate().responseJSON(completionHandler: { response in
                HUD.dismiss()
                guard response.result.error == nil else {
                    var message: String!
                    if let httpStatusCode = response.response?.statusCode {
                        switch httpStatusCode {
                        case 400:
                            message = "Bad Request."
                        case 401:
                            message = "Incorrect password for user '\(self.usernameField.text!)'."
                        default:
                            message = response.result.error!.localizedDescription
                        }
                    }
                    let error = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
                    error.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                    self.presentViewController(error, animated: true, completion: nil)
                    NSLog("Error is %@", response.result.error!)
                    return
                }
                let HUD = JGProgressHUD(style: .ExtraLight)
                HUD.textLabel.text = "Issue Created"
                
                HUD.indicatorView = JGProgressHUDSuccessIndicatorView()
                HUD.showInView(self.view)
                HUD.dismissAfterDelay(2.0)
                for textField in [self.usernameField, self.passwordField, self.titleField] {
                    // Reset view
                    textField.text?.removeAll()
                    textField.resignFirstResponder()
                }
                self.descriptionField.text.removeAll()
                self.descriptionField.resignFirstResponder()
            })
            return
        }
        
        let error = UIAlertController(title: "Error", message: "All fields are required", preferredStyle: .Alert)
        error.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(error, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onePasswordSignInButton?.hidden = !OnePasswordExtension.sharedExtension().isAppExtensionAvailable()
    }
    
}
