

import UIKit
import FloatRatingView
import AlamofireImage
import ColorArt
import PopcornTorrent

class TVShowDetailViewController: DetailItemOverviewViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, PCTPlayerViewControllerDelegate {
    
    enum type {
        case Anime
        case TvShow
    }
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var showTitleLabel: UILabel!
    @IBOutlet var showRatingView: FloatRatingView!
    @IBOutlet var showDescriptionView: UITextView!
    @IBOutlet var showInfoLabel: UILabel!
    @IBOutlet var tableHeaderView: UIView!
    
    override var minimumHeight: CGFloat {
        get {
            return 110.0
        }
    }
    
    let interactor = PCTEpisodeDetailPercentDrivenInteractiveTransition()

    var currentType: type = .TvShow
    var currentItem: PCTShow!
    var episodes: [PCTEpisode]?
    var seasons: [Int]?
    var episodesLeftInShow: [PCTEpisode]!
    
    var currentSeason: Int! {
        didSet {
            self.tableView?.reloadData()
        }
    }
    var currentSeasonArray = [PCTEpisode]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        WatchlistManager.episodeManager.getProgress()
        WatchlistManager.showManager.getWatched() {
            self.tableView?.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let adjustForTabbarInsets = UIEdgeInsetsMake(0, 0, CGRectGetHeight(tabBarController!.tabBar.frame), 0)
        tableView!.contentInset = adjustForTabbarInsets
        tableView!.scrollIndicatorInsets = adjustForTabbarInsets
        tableView!.rowHeight = UITableViewAutomaticDimension
        navigationItem.title = currentItem.title
        showTitleLabel.text = currentItem.title
        showInfoLabel.text = "\(currentItem.year)"
        showRatingView.rating = currentItem.rating
        if currentType == .Anime {
            AnimeAPI.sharedInstance.getAnimeInfo(currentItem.animeId!, imdbId: currentItem.imdbId) { (synopsis, status, imageURL, episodes, seasons, rating) in
                self.currentItem.synopsis = synopsis
                self.currentItem.status = status
                self.currentItem.coverImageAsString = imageURL
                self.episodes = episodes
                for var episode in self.episodes! {
                    episode.show = self.currentItem
                }
                self.seasons = seasons
                self.currentItem.rating = rating
                self.setUpSegmenedControl()
                self.tableView!.reloadData()
            }
        } else {
            TVAPI.sharedInstance.getShowInfo(currentItem.imdbId) { (genres, status, synopsis, episodes, seasons) in
                self.currentItem.genres = genres
                self.currentItem.status = status
                self.currentItem.synopsis = synopsis
                var updatedEpisodes = [PCTEpisode]()
                for var episode in episodes {
                    episode.show = self.currentItem
                    updatedEpisodes.append(episode)
                }
                self.episodes = updatedEpisodes
                self.seasons = seasons
                self.showDescriptionView.text = self.currentItem.synopsis
                self.tableView!.sizeHeaderToFit()
                self.showInfoLabel.text = "\(self.currentItem.year) ● \(self.currentItem.status!.capitalizedString) ● \(self.currentItem.genres![0].capitalizedString)"
                self.setUpSegmenedControl()
                self.tableView!.reloadData()
            }
        }
        backgroundImageView.af_setImageWithURL(NSURL(string: currentItem.coverImageAsString.stringByReplacingOccurrencesOfString("thumb", withString: "original"))!, placeholderImage: UIImage(named: "Placeholder"), imageTransition: .CrossDissolve(animationLength))
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            tableView.tableHeaderView = tableHeaderView
            return 0
        }
        tableView.tableHeaderView = nil
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if episodes != nil {
            currentSeasonArray.removeAll()
            currentSeasonArray = getGroupedEpisodesBySeason(currentSeason)
            return currentSeasonArray.count
        }
        return 0
    }
    
    func getGroupedEpisodesBySeason(season: Int) -> [PCTEpisode] {
        var array = [PCTEpisode]()
        for index in seasons! {
            if season == index {
                for episode in episodes! {
                    if episode.season == index {
                        array.append(episode)
                    }
                }
            }
        }
        return array
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! TVShowDetailTableViewCell
        cell.titleLabel.text = currentSeasonArray[indexPath.row].title
        cell.seasonLabel.text = "E" + String(currentSeasonArray[indexPath.row].episode)
        cell.tvdbId = currentSeasonArray[indexPath.row].tvdbId
        return cell
    }
    
    
    // MARK: - SegmentedControl
    
    func setUpSegmenedControl() {
        segmentedControl.removeAllSegments()
        segmentedControl.insertSegmentWithTitle("ABOUT", atIndex: 0, animated: true)
        for index in seasons! {
            segmentedControl.insertSegmentWithTitle("SEASON \(index)", atIndex: index, animated: true)
        }
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(11, weight: UIFontWeightMedium)],forState: UIControlState.Normal)
        segmentedControlDidChangeSegment(segmentedControl)
    }
    
    @IBAction func segmentedControlDidChangeSegment(segmentedControl: UISegmentedControl) {
        currentSeason = segmentedControl.selectedSegmentIndex == 0 ? Int.max: seasons?[segmentedControl.selectedSegmentIndex - 1]
        if tableView!.frame.height > tableView!.contentSize.height + tableView!.contentInset.bottom {
            resetToEnd(tableView!)
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == "showDetail" {
            let indexPath = tableView!.indexPathForCell(sender as! TVShowDetailTableViewCell)
            let destinationController = segue.destinationViewController as! EpisodeDetailViewController
            destinationController.currentEpisode = currentSeasonArray[indexPath!.row]
            var allEpisodes = [PCTEpisode]()
            for season in segmentedControl.selectedSegmentIndex..<segmentedControl.numberOfSegments {
                allEpisodes += getGroupedEpisodesBySeason(season)
                if season == currentSeason // Remove episodes up to the next episode eg. If row 2 is selected, row 0-2 will be deleted.
                {
                    allEpisodes.removeFirst(indexPath!.row + 1)
                }
            }
            episodesLeftInShow = allEpisodes
            destinationController.delegate = self
            destinationController.transitioningDelegate = self
            destinationController.modalPresentationStyle = .Custom
            destinationController.interactor = interactor
        }
    }
    
    func loadMovieTorrent(media: PCTEpisode, animated: Bool, onChromecast: Bool = GCKCastContext.sharedInstance().castState == .Connected) {
        let loadingViewController = storyboard!.instantiateViewControllerWithIdentifier("LoadingViewController") as! LoadingViewController
        loadingViewController.transitioningDelegate = self
        loadingViewController.backgroundImage = backgroundImageView.image
        presentViewController(loadingViewController, animated: animated, completion: nil)
        let magnet = cleanMagnet(media.currentTorrent.url)
        let moviePlayer = self.storyboard!.instantiateViewControllerWithIdentifier("PCTPlayerViewController") as! PCTPlayerViewController
        moviePlayer.delegate = self
        let currentProgress = WatchlistManager.episodeManager.currentProgress(media.tvdbId)
        PTTorrentStreamer.sharedStreamer().startStreamingFromFileOrMagnetLink(magnet, progress: { status in
            loadingViewController.progress = status.bufferingProgress
            loadingViewController.speed = Int(status.downloadSpeed)
            loadingViewController.seeds = Int(status.seeds)
            loadingViewController.updateProgress()
            moviePlayer.bufferProgressView?.progress = status.totalProgreess
            }, readyToPlay: { (videoFileURL, videoFilePath) in
                loadingViewController.dismissViewControllerAnimated(false, completion: nil)
                var nextEpisode: PCTEpisode? = nil
                if self.episodesLeftInShow.count > 0 {
                    nextEpisode = self.episodesLeftInShow.first
                    self.episodesLeftInShow.removeFirst()
                }
                if onChromecast {
                    let manager = GoogleCastManager()
                    //manager.castMetadata = PCTCastMetaData(episode: media, subtitle: media.currentSubtitle, duration: NSTimeInterval(media.runtime * 60), startPosition: NSTimeInterval(currentProgress), url: videoFileURL.relativeString!)
                    manager.sessionManager(GCKCastContext.sharedInstance().sessionManager, didStartSession: GCKSession())
                } else {
                    moviePlayer.play(media, fromURL: videoFileURL, progress: currentProgress, nextEpisode: nextEpisode, directory: videoFilePath.URLByDeletingLastPathComponent!)
                    self.presentViewController(moviePlayer, animated: true, completion: nil)
                }
        }) { error in
            loadingViewController.cancelButtonPressed()
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            print("Error is \(error)")
        }
    }
    
    func playNext(episode: PCTEpisode) {
        var episode = episode
        if episode.currentTorrent == nil {
            episode.currentTorrent = episode.torrents.first!
        }
        loadMovieTorrent(episode, animated: false)
    }
    
    // MARK: - Presentation
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is LoadingViewController {
            return PCTLoadingViewAnimatedTransitioning(isPresenting: true, sourceController: source)
        } else if presented is EpisodeDetailViewController {
            return PCTEpisodeDetailAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is LoadingViewController {
            return PCTLoadingViewAnimatedTransitioning(isPresenting: false, sourceController: self)
        } else if dismissed is EpisodeDetailViewController {
            return PCTEpisodeDetailAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
    
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        return presented is EpisodeDetailViewController ? PCTEpisodeDetailPresentationController(presentedViewController: presented, presentingViewController: presenting) : nil
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
