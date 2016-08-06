

import UIKit
import Reachability

protocol ItemOverviewDelegate: class {
    func search(text: String)
    func didDismissSearchController(searchController: UISearchController)
    func loadNextPage(page: Int, searchTerm: String?, removeCurrentData: Bool)
    func shouldRefreshCollectionView() -> Bool
}

class ItemOverview: UICollectionViewController, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UICollectionViewDelegateFlowLayout {
    
    weak var delegate: ItemOverviewDelegate?
    
    let searchBlockDelay: CGFloat = 0.25
    var searchBlock: dispatch_cancelable_block_t?
    
    var isLoading: Bool = false
    var hasNextPage: Bool = false
    var currentPage: Int = 1
    
    let cache = NSCache()
    
    var error: NSError?
    
    var filterHeader: FilterCollectionReusableView?
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        collectionView?.removeObserver(self, forKeyPath: "frame")
        searchController.searchBar.hidden = true
        searchController.searchBar.resignFirstResponder()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadWithError), name: errorNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reachabilityChanged(_:)), name: kReachabilityChangedNotification, object: nil)
        collectionView?.addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions(rawValue: 0), context: nil) // Resize collection view cells when the view resizes. eg. when changing the size of the split view on iPads
        searchController.searchBar.hidden = false
        searchController.searchBar.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshCollectionView(_:)), forControlEvents: .ValueChanged)
        collectionView?.addSubview(refreshControl)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        observeValueForKeyPath("frame", ofObject: collectionView, change: nil, context: nil) // If view size has changed while view isn't first responder, force a resize upon reappearing.
    }
    
    func reachabilityChanged(notification: NSNotification) {
        let reachability = notification.object! as! Reachability
        if reachability.isReachableViaWiFi() || reachability.isReachableViaWWAN() {
            if let delegate = delegate where delegate.shouldRefreshCollectionView() {
                delegate.loadNextPage(currentPage, searchTerm: searchController.searchBar.text, removeCurrentData: true)
            }
        }
    }
    
    func refreshCollectionView(sender: UIRefreshControl) {
        delegate?.loadNextPage(currentPage, searchTerm: searchController.searchBar.text, removeCurrentData: true)
        sender.endRefreshing()
    }
    
    func reloadWithError(error: NSNotification) {
        self.error = (error.object as! NSError)
        collectionView?.reloadData()
    }
    
    lazy var searchController: UISearchController = {
        let svc = UISearchController(searchResultsController: nil)
        svc.searchResultsUpdater = self
        svc.delegate = self
        svc.searchBar.delegate = self
        svc.searchBar.barStyle = .Black
        svc.searchBar.translucent = false
        svc.hidesNavigationBarDuringPresentation = false
        svc.dimsBackgroundDuringPresentation = false
        svc.searchBar.keyboardAppearance = .Dark
        return svc
    }()
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView == collectionView {
            let y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom
            let height = scrollView.contentSize.height
            let reloadDistance: CGFloat = 10
            if(y > height + reloadDistance && isLoading == false && hasNextPage == true) {
                collectionView?.contentInset = UIEdgeInsetsMake(69, 0, 80, 0)
                let background = UIView(frame: collectionView!.frame)
                let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
                indicator.startAnimating()
                indicator.translatesAutoresizingMaskIntoConstraints = false
                background.addSubview(indicator)
                background.addConstraint(NSLayoutConstraint(item: indicator, attribute: .CenterX, relatedBy: .Equal, toItem: background, attribute: .CenterX, multiplier: 1, constant: 0))
                background.addConstraint(NSLayoutConstraint(item: indicator, attribute: .Bottom, relatedBy: .Equal, toItem: background, attribute: .Bottom, multiplier: 1, constant: -55))
                collectionView?.backgroundView = background
                currentPage += 1
                delegate?.loadNextPage(currentPage, searchTerm: nil, removeCurrentData: false)
            }
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if !(searchController.searchBar.text?.isEmpty)! {
            if searchBlock != nil {
                cancel_block(searchBlock)
            }
            searchBlock = dispatch_after_delay(searchBlockDelay, {
                self.delegate?.search(searchController.searchBar.text!)
            })
        } else {
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
            indicator.center = collectionView!.center
            collectionView!.backgroundView = indicator
            indicator.sizeToFit()
            indicator.startAnimating()
        }
    }
    
    func collectionView(collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if collectionView.bounds.width/(195 * 4) >= 1 // Check if the view can fit more than 4 cells across
        {
            return CGSizeMake(195, 280)
        } else {
            let wid = (collectionView.bounds.width/CGFloat(2))-8
            let ratio = 230/wid
            let hei = 345/ratio
            
            return CGSizeMake(wid, hei)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return filterHeader?.hidden == true ? CGSizeMake(CGFloat.min, CGFloat.min): CGSizeMake(view.frame.size.width, 50)
    }

}

extension UISearchController {
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        // Fixes status bar color changing from black to white upon presentation.
        return .LightContent
    }
}
