

import UIKit
import Reachability
import AlamofireNetworkActivityIndicator
import GoogleCast

let safariLoginNotification = "kCloseSafariViewControllerNotification"
let errorNotification = "kErrorNotification"
let traktAuthenticationErrorNotification = "kTraktAuthenticationErrorNotification"
let animationLength = 0.37

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var reachability: Reachability?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NetworkActivityIndicatorManager.sharedManager.isEnabled = true
        window?.tintColor = UIColor(red:0.37, green:0.41, blue:0.91, alpha:1.0)
        reachability = Reachability.reachabilityForInternetConnection()
        reachability!.startNotifier()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reachabilityChanged(_:)), name: kReachabilityChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(problemAuthenticatingTrakt), name: traktAuthenticationErrorNotification, object: nil)
        if !NSUserDefaults.standardUserDefaults().boolForKey("TOSAccepted") {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            self.window?.makeKeyAndVisible()
            self.window?.rootViewController?.presentViewController(storyboard.instantiateViewControllerWithIdentifier("TermsOfServiceNavigationController"), animated: false, completion: nil)
            
        }
        GCKCastContext.setSharedInstanceWithOptions(GCKCastOptions(receiverApplicationID: kGCKMediaDefaultReceiverApplicationID))
        mkdir("/var/mobile/Library/Popcorn Time", 0755)
        return true
    }
    
    func problemAuthenticatingTrakt() {
            let errorAlert = UIAlertController(title: "Problem authenticating with trakt", message: nil, preferredStyle: .Alert)
            errorAlert.addAction(UIAlertAction(title: "Sign Out", style: .Destructive, handler: { (action) in
                OAuthCredential.deleteCredentialWithIdentifier("trakt")
                NSUserDefaults.standardUserDefaults().setBool(false, forKey: "AuthorizedTrakt")
            }))
            errorAlert.addAction(UIAlertAction(title: "Settings", style: .Default, handler:{ (action) in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let settings = storyboard.instantiateViewControllerWithIdentifier("SettingsTableViewController") as! SettingsTableViewController
                self.window?.rootViewController?.navigationController?.pushViewController(settings, animated: true)
            }))
            self.window?.rootViewController?.presentViewController(errorAlert, animated: true, completion: nil)
    }
    
    func reachabilityChanged(notification: NSNotification) {
        if !reachability!.isReachableViaWiFi() && !reachability!.isReachableViaWWAN() {
            dispatch_async(dispatch_get_main_queue(), {
                let errorAlert = UIAlertController(title: "Oops..", message: "You are not connected to the internet anymore. Popcorn Time will automatically reconnect once it detects a valid internet connection.", preferredStyle: UIAlertControllerStyle.Alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler:nil))
                self.window?.rootViewController?.presentViewController(errorAlert, animated: true, completion: nil)
            })
        }
    }
	
	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if sourceApplication! == "com.apple.SafariViewService" || sourceApplication! == "com.apple.mobilesafari" {
            NSNotificationCenter.defaultCenter().postNotificationName(safariLoginNotification, object: url)
        }
		return true
	}

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
    }


}

