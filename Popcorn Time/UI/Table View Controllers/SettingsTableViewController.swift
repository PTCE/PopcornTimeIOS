

import UIKit
import SafariServices

class SettingsTableViewController: UITableViewController, TablePickerViewDelegate {

    let ud = NSUserDefaults.standardUserDefaults()
    
    var safariViewController: SFSafariViewController!
    
    @IBOutlet weak var switchStreamOnCellular: UISwitch!
    @IBOutlet weak var removeCacheOnPlayerExit: UISwitch!
    @IBOutlet weak var segmentedQuality: UISegmentedControl!
	@IBOutlet weak var languageButton: UIButton!
    @IBOutlet weak var traktSignInButton: UIButton!
    @IBOutlet weak var openSubsSignInButton: UIButton!
	
	var tablePickerView : TablePickerView?
    let qualities = ["480p", "720p", "1080p"]
	
    var state: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		addTablePicker()
        showSettings()
        updateSignedInStatus(traktSignInButton, isSignedIn: ud.boolForKey("AuthorizedTrakt"))
        updateSignedInStatus(openSubsSignInButton, isSignedIn: ud.boolForKey("AuthorizedOpenSubs"))
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(safariLogin(_:)), name: safariLoginNotification, object: nil)
    }
    
    func showSettings() {        
        // Set StreamOnCellular
        switchStreamOnCellular.on = ud.boolForKey("StreamOnCellular")
        removeCacheOnPlayerExit.on = ud.boolForKey("removeCacheOnPlayerExit")
		
		// Set preferred subtitle language
		if let preferredSubtitleLanguage = ud.objectForKey("PreferredSubtitleLanguage") as? String {
            if preferredSubtitleLanguage != "None" {
                tablePickerView?.setSelected([preferredSubtitleLanguage])
                languageButton.setTitle(preferredSubtitleLanguage, forState: .Normal)
            } else {
                languageButton.setTitle("None", forState: .Normal)
            }
		} else {
            languageButton.setTitle("None", forState: .Normal)
		}
		
        // Set preferred quality
        let qualityInSettings = ud.objectForKey("PreferredQuality") as? String
        var selectedQualityIndex = 0
        segmentedQuality.removeAllSegments()
        for (index, quality) in qualities.enumerate() {
            segmentedQuality.insertSegmentWithTitle(quality, atIndex: index, animated: true)
            if let qualityInSettings = qualityInSettings {
                if quality == qualityInSettings {
                    selectedQualityIndex = index
                }
            }
        }
        
        segmentedQuality.selectedSegmentIndex = selectedQualityIndex
    }
    
    func updateSignedInStatus(sender: UIButton, isSignedIn: Bool) {
        sender.setTitle(isSignedIn ? "Sign Out": "Authorize", forState: .Normal)
        sender.setTitleColor(isSignedIn ? UIColor(red: 230.0/255.0, green: 46.0/255.0, blue: 37.0/255.0, alpha: 1.0) : view.window?.tintColor!, forState: .Normal)
    }
	
	func addTablePicker() {
        tablePickerView = TablePickerView(superView: self.view, sourceArray: NSLocale.commonLanguages(), self)
		self.tabBarController?.view.addSubview(tablePickerView!)
	}
    
    func tablePickerView(tablePickerView: TablePickerView, didChange items: [String]) {
        if items.count > 0 {
            ud.setObject(items[0], forKey: "PreferredSubtitleLanguage")
            languageButton.setTitle(items[0], forState: .Normal)
        } else {
            ud.setObject("None", forKey: "PreferredSubtitleLanguage")
            languageButton.setTitle("None", forState: .Normal)
        }
    }
	
	override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
		tablePickerView?.hide()
        ud.synchronize()
	}
    
    @IBAction func streamOnCellular(sender: UISwitch) {
        ud.setBool(sender.on, forKey: "StreamOnCellular")
    }
    
    @IBAction func preferredQuality(control: UISegmentedControl) {
        let resultAsText = control.titleForSegmentAtIndex(control.selectedSegmentIndex)
        ud.setObject(resultAsText, forKey: "PreferredQuality")
    }
	
	@IBAction func preferredSubtitleLanguage(sender: AnyObject) {
		tablePickerView?.toggle()
	}
    
    @IBAction func authorizeTraktTV(sender: UIButton) {
        if ud.boolForKey("AuthorizedTrakt") {
            let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to Sign Out?", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .Destructive, handler: { action in
                OAuthCredential.deleteCredentialWithIdentifier("trakt")
                self.ud.setBool(false, forKey: "AuthorizedTrakt")
                self.updateSignedInStatus(sender, isSignedIn: false)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        } else {
            state = randomString(length: 15)
            openUrl("https://trakt.tv/oauth/authorize?client_id=a3b34d7ce9a7f8c1bb216eed6c92b11f125f91ee0e711207e1030e7cdc965e19&redirect_uri=PopcornTime%3A%2F%2Ftrakt&response_type=code&state=\(state)")
        }
    }
    
    @IBAction func authorizeOpenSubs(sender: UIButton) {
        if ud.boolForKey("AuthorizedOpenSubs") {
            let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to Sign Out?", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .Destructive, handler: { action in
            
                let credential = NSURLCredentialStorage.sharedCredentialStorage().credentialsForProtectionSpace(OpenSubtitles.sharedInstance.protectionSpace)!.values.first!
                NSURLCredentialStorage.sharedCredentialStorage().removeCredential(credential, forProtectionSpace: OpenSubtitles.sharedInstance.protectionSpace)
                self.ud.setBool(false, forKey: "AuthorizedOpenSubs")
                self.updateSignedInStatus(sender, isSignedIn: false)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        } else {
            var alert = UIAlertController(title: "Sign In", message: "VIP account required.", preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler({ (textField) in
                textField.placeholder = "Username"
            })
            alert.addTextFieldWithConfigurationHandler({ (textField) in
                textField.placeholder = "Password"
                textField.secureTextEntry = true
            })
            alert.addAction(UIAlertAction(title: "Sign In", style: .Default, handler: { (action) in
                let credential = NSURLCredential(user: alert.textFields![0].text!, password: alert.textFields![1].text!, persistence: .Permanent)
                NSURLCredentialStorage.sharedCredentialStorage().setCredential(credential, forProtectionSpace: OpenSubtitles.sharedInstance.protectionSpace)
                OpenSubtitles.sharedInstance.login({
                    self.ud.setBool(true, forKey: "AuthorizedOpenSubs")
                    self.updateSignedInStatus(sender, isSignedIn: true)
                    }, error: { error in
                        NSURLCredentialStorage.sharedCredentialStorage().removeCredential(credential, forProtectionSpace: OpenSubtitles.sharedInstance.protectionSpace)
                        alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                })
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func showTwitter(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://twitter.com/popcorntimetv")!)
    }
    
    @IBAction func clearCache(sender: UIButton) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
        controller.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        do {
            let size = NSFileManager.defaultManager().folderSizeAtPath(downloadsDirectory)
            try NSFileManager.defaultManager().removeItemAtURL(NSURL(fileURLWithPath: downloadsDirectory))
            controller.title = "Success"
            if size == 0 {
                controller.message = "Cache was already empty, no disk space was reclamed."
            } else {
               controller.message = "Cleaned \(size) bytes."
            }
        } catch {
            controller.title = "Failed"
            controller.message = "Error cleanining cache."
            print("Error: \(error)")
        }
        presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func removeCacheOnPlayerExit(sender: UISwitch) {
        ud.setBool(sender.on, forKey: "removeCacheOnPlayerExit")
    }
    
    @IBAction func showWebsite(sender: AnyObject) {
        openUrl("http://popcorntime.sh")
    }
    
    func openUrl(url : String) {
        self.safariViewController = SFSafariViewController(URL: NSURL(string: url)!)
        self.safariViewController.view.tintColor = UIColor(red:0.37, green:0.41, blue:0.91, alpha:1.0)
        presentViewController(self.safariViewController, animated: true, completion: nil)
    }
    
    func safariLogin(notification: NSNotification) {
        safariViewController.dismissViewControllerAnimated(true, completion: nil)
        let url = notification.object as! NSURL
        let query = url.query!.urlStringValues()
        let state = query["state"]
        guard state != self.state else {
            dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
                do {
                    let credential = try OAuthCredential(URLString: "https://api-v2launch.trakt.tv/oauth/token", code: query["code"]!, redirectURI: "PopcornTime://trakt", clientID: TraktTVAPI.sharedInstance.clientId, clientSecret: TraktTVAPI.sharedInstance.clientSecret, useBasicAuthentication: false)
                    OAuthCredential.storeCredential(credential, identifier: "trakt")
                    dispatch_async(dispatch_get_main_queue(), {
                        self.ud.setBool(true, forKey: "AuthorizedTrakt")
                        self.updateSignedInStatus(self.traktSignInButton, isSignedIn: true)
                    })
                } catch {}
            }
            return
        }
        let error = UIAlertController(title: "Error", message: "Uh Oh! It looks like your connection has been compromised. You may be a victim of Cross Site Request Forgery. If you are on a public WiFi network please disconnect immediately and contact the network administrator.", preferredStyle: .Alert)
        error.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        error.addAction(UIAlertAction(title: "Learn More", style: .Default, handler: { action in
            UIApplication.sharedApplication().openURL(NSURL(string: "http://www.veracode.com/security/csrf")!)
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        presentViewController(error, animated: true, completion: nil)
    }
}
