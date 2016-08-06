

import UIKit
import GoogleCast

class DetailItemOverviewViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate {
    
    var progressiveness: CGFloat = 0.0
    var lastTranslation: CGFloat = 0.0
    var lastHeaderHeight: CGFloat = 0.0
    var minimumHeight: CGFloat {
        return 64.0
    }
    let maximumHeight: CGFloat = 430.0
    
    @IBOutlet var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var scrollView: PCTScrollView?
    @IBOutlet var tableView: PCTTableView?
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var gradientViews: [GradientView]!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var castButton: CastIconBarButtonItem!

    enum ScrollDirection {
        case Down
        case Up
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateCastStatus), name: kGCKCastStateDidChangeNotification, object: nil)
        updateCastStatus()
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics:.Default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.backgroundColor = UIColor.clearColor()
        self.navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(self.progressiveness)]
        if transitionCoordinator()?.viewControllerForKey(UITransitionContextFromViewControllerKey) is PCTPlayerViewController {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            if let scrollView = scrollView {
                resetToEnd(scrollView, animated: false)
            } else {
                resetToEnd(tableView!, animated: false)
            }
            let frame = self.tabBarController?.tabBar.frame
            let offsetY = -frame!.size.height
            self.tabBarController?.tabBar.frame = CGRectOffset(frame!, 0, offsetY)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if transitionCoordinator()?.viewControllerForKey(UITransitionContextToViewControllerKey) == self.navigationController?.topViewController {
            self.navigationController!.navigationBar.setBackgroundImage(nil, forBarMetrics:.Default)
            self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        (castButton.customView as! CastIconButton).addTarget(self, action: #selector(castButtonTapped), forControlEvents: .TouchUpInside)
    }
    
    @IBAction func handleGesture(sender: UIPanGestureRecognizer) {
        let translation = sender.translationInView(sender.view!.superview!)
        let offset = translation.y - lastTranslation
        let scrollDirection: ScrollDirection = offset > 0 ? .Up : .Down
        var scrollingView: AnyObject
        if let tableView = tableView {
            scrollingView = tableView
        } else {
            scrollingView = scrollView!
        }
    
        if sender.state == .Changed || sender.state == .Began {
            if (headerHeightConstraint.constant + offset) >= minimumHeight && scrollingView.valueForKey("programaticScrollEnabled")!.boolValue == false {
                if ((headerHeightConstraint.constant + offset) - minimumHeight) <= 8.0 // Stops scrolling from sticking just before we transition to scroll view input.
                {
                    headerHeightConstraint.constant = self.minimumHeight
                    updateScrolling(true)
                } else {
                    headerHeightConstraint.constant += offset
                    updateScrolling(false)
                }
            }
            if headerHeightConstraint.constant == minimumHeight && scrollingView.valueForKey("isAtTop")!.boolValue
            {
                if scrollDirection == .Up {
                    scrollingView.performSelector(Selector("setProgramaticScrollEnabled:"), withObject: NSNumber(bool: false))
                } else // If header is fully collapsed and we are not at the end of scroll view, hand scrolling to scroll view
                {
                    scrollingView.performSelector(Selector("setProgramaticScrollEnabled:"), withObject: NSNumber(bool: true))
                }
            }
            lastTranslation = translation.y
        } else if sender.state == .Ended {
            if headerHeightConstraint.constant > maximumHeight {
                headerHeightConstraint.constant = maximumHeight
                updateScrolling(true)
            } else if scrollingView.valueForKey("frame")!.CGRectValue().size.height > scrollingView.valueForKey("contentSize")!.CGSizeValue().height + scrollingView.valueForKey("contentInset")!.UIEdgeInsetsValue().bottom {
                resetToEnd(scrollingView)
            }
            lastTranslation = 0.0
        }
    }
    
    
    func updateScrolling(animated: Bool) {
        self.progressiveness = 1.0 - (self.headerHeightConstraint.constant - self.minimumHeight)/(self.maximumHeight - self.minimumHeight)
        if animated {
            UIView.animateWithDuration(animationLength, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .AllowUserInteraction, animations: { 
                self.view.layoutIfNeeded()
                self.blurView.alpha = self.progressiveness
                self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(self.progressiveness)]
                }, completion: nil)
        } else {
            self.blurView.alpha = self.progressiveness
            self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(self.progressiveness)]
        }
    }
    
    func resetToEnd(scrollingView: AnyObject, animated: Bool = true) {
        headerHeightConstraint.constant += scrollingView.valueForKey("frame")!.CGRectValue().size.height - (scrollingView.valueForKey("contentSize")!.CGSizeValue().height + scrollingView.valueForKey("contentInset")!.UIEdgeInsetsValue().bottom)
        if headerHeightConstraint.constant > maximumHeight {
            headerHeightConstraint.constant = maximumHeight
        }
        if headerHeightConstraint.constant >= minimumHeight // User does not go over the "bridge area" so programmatic scrolling has to be explicitly disabled
        {
            scrollingView.performSelector(Selector("setProgramaticScrollEnabled:"), withObject: NSNumber(bool: false))
        }
        updateScrolling(animated)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - Presentation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        fixIOS9PopOverAnchor(segue)
        if segue.identifier == "showCasts", let vc = (segue.destinationViewController as? UINavigationController)?.viewControllers.first as? StreamToDevicesTableViewController {
            segue.destinationViewController.popoverPresentationController?.delegate = self
            vc.onlyShowCastDevices = true
        }
    }
    
    func castButtonTapped() {
        performSegueWithIdentifier("showCasts", sender: castButton)
    }
    
    func updateCastStatus() {
        (castButton.customView as! CastIconButton).status = GCKCastContext.sharedInstance().castState
    }
    
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        (controller.presentedViewController as! UINavigationController).topViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(dismiss))
        return controller.presentedViewController
        
    }
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

class PCTScrollView: UIScrollView {
    var programaticScrollEnabled = NSNumber(bool: false)
    
    override var contentOffset: CGPoint {
        didSet {
            if !programaticScrollEnabled.boolValue {
                super.contentOffset = CGPointZero
            }
        }
    }
}

class PCTTableView: UITableView {
    var programaticScrollEnabled = NSNumber(bool: false)
    
    override var contentOffset: CGPoint {
        didSet {
            if !programaticScrollEnabled.boolValue {
                super.contentOffset = CGPointZero
            }
        }
    }
}
