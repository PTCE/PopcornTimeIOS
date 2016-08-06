

import UIKit
import FloatRatingView
import XCDYouTubeKit
import AlamofireImage
import ColorArt
import PopcornTorrent

class MovieDetailViewController: DetailItemOverviewViewController, TablePickerViewDelegate, UIViewControllerTransitioningDelegate {
    
    @IBOutlet var movieTitleLabel: UILabel!
    @IBOutlet var movieRatingView: FloatRatingView!
    @IBOutlet var movieDescriptionView: UITextView!
    @IBOutlet var movieInfoLabel: UILabel!
    @IBOutlet var torrentHealth: CircularView!
    @IBOutlet var qualityBtn: UIButton!
    @IBOutlet var subtitlesButton: UIButton!
    @IBOutlet var playButton: PCTBorderButton!
    @IBOutlet var watchedBtn: UIBarButtonItem!
    
    var currentItem: PCTMovie!
    var subtitlesTablePickerView: TablePickerView!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        WatchlistManager.movieManager.getProgress()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = currentItem.title
        watchedBtn.image = getWatchedButtonImage()
        let adjustForTabbarInsets = UIEdgeInsetsMake(0, 0, CGRectGetHeight(tabBarController!.tabBar.frame), 0)
        scrollView!.contentInset = adjustForTabbarInsets
        scrollView!.scrollIndicatorInsets = adjustForTabbarInsets
        movieTitleLabel.text = currentItem.title
        movieDescriptionView.text = currentItem.summary
        movieRatingView.rating = Float(currentItem.rating)
        movieInfoLabel.text = "\(currentItem.year) ● \(currentItem.runtime) min ● \(currentItem.genres[0])"
        currentItem.currentTorrent = currentItem.torrents.first!
        for torrent in currentItem.torrents {
            if torrent.quality == NSUserDefaults.standardUserDefaults().objectForKey("PreferredQuality") as? String {
                currentItem.currentTorrent = torrent
            }
        }
        if currentItem.torrents.count > 1 {
            qualityBtn.setTitle("\(currentItem.currentTorrent.quality!) ▾", forState: .Normal)
        } else {
            qualityBtn.setTitle("\(currentItem.currentTorrent.quality!)", forState: .Normal)
            qualityBtn.userInteractionEnabled = false
        }
        let colorArt = SLColorArt(image: backgroundImageView.image)
        playButton.borderColor = colorArt.secondaryColor
        OpenSubtitles.sharedInstance.login({
            OpenSubtitles.sharedInstance.search(imdbId: self.currentItem.imdbId, completion: {
                subtitles in
                self.currentItem.subtitles = subtitles
                if subtitles.count == 0 {
                    self.subtitlesButton.setTitle("No Subtitles Available", forState: .Normal)
                } else {
                    self.subtitlesButton.setTitle("None ▾", forState: .Normal)
                    self.subtitlesButton.userInteractionEnabled = true
                    if let preferredSubtitle = NSUserDefaults.standardUserDefaults().objectForKey("PreferredSubtitleLanguage") as? String {
                        for subtitle in subtitles {
                            if subtitle.language == preferredSubtitle {
                                self.currentItem.currentSubtitle = subtitle
                                self.subtitlesButton.setTitle("\(subtitle.language) ▾", forState: .Normal)
                            }
                        }
                    }
                }
                self.subtitlesTablePickerView = TablePickerView(superView: self.view, sourceDict: PCTSubtitle.dictValue(subtitles), self)
                if let link = self.currentItem.currentSubtitle?.link {
                    self.subtitlesTablePickerView?.setSelected([link])
                }
                self.tabBarController?.view.addSubview(self.subtitlesTablePickerView!)
            })
        })
        torrentHealth.backgroundColor = currentItem.currentTorrent.health.color()
        TraktTVAPI.sharedInstance.getMovieMeta(currentItem.imdbId) { backgroundImageAsString in
            self.currentItem.coverImageAsString = backgroundImageAsString
            self.backgroundImageView.af_setImageWithURLRequest(NSURLRequest(URL: NSURL(string: backgroundImageAsString)!), placeholderImage: UIImage(named: "Placeholder"), imageTransition: .CrossDissolve(animationLength), completion: { response in
                guard response.result.isFailure else {
                    let colorArt = SLColorArt(image: response.result.value!)
                    self.playButton.borderColor = colorArt.secondaryColor
                    return
                }
            })
        }
    }
    
    func getWatchedButtonImage() -> UIImage {
        var watchedImage = UIImage(named: "WatchedOff")!.imageWithRenderingMode(.AlwaysOriginal)
        if WatchlistManager.movieManager.isWatched(currentItem.imdbId) {
            watchedImage = UIImage(named: "WatchedOn")!.imageWithRenderingMode(.AlwaysOriginal)
        }
        return watchedImage
    }
    
    @IBAction func toggleWatched() {
        WatchlistManager.movieManager.toggleWatched(currentItem.imdbId)
        watchedBtn.image = getWatchedButtonImage()
    }
    
    @IBAction func changeQualityTapped(sender: UIButton) {
        let quality = UIAlertController(title:"Select Quality", message:nil, preferredStyle:UIAlertControllerStyle.ActionSheet)
        for torrent in currentItem.torrents {
            quality.addAction(UIAlertAction(title: "\(torrent.quality!) \(torrent.size!)", style: .Default, handler: { action in
                self.currentItem.currentTorrent = torrent
                self.qualityBtn.setTitle("\(torrent.quality!) ▾", forState: .Normal)
                self.torrentHealth.backgroundColor = torrent.health.color()
            }))
        }
        quality.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        quality.popoverPresentationController?.sourceView = sender
        fixPopOverAnchor(quality)
        presentViewController(quality, animated: true, completion: nil)
    }
    
    @IBAction func changeSubtitlesTapped(sender: UIButton) {
        subtitlesTablePickerView.toggle()
    }
    
    @IBAction func watchNowTapped(sender: UIButton) {
        let onWifi: Bool = (UIApplication.sharedApplication().delegate! as! AppDelegate).reachability!.isReachableViaWiFi()
        let wifiOnly: Bool = !NSUserDefaults.standardUserDefaults().boolForKey("StreamOnCellular")
        if !wifiOnly || onWifi {
            loadMovieTorrent(currentItem)
        } else {
            let errorAlert = UIAlertController(title: "Cellular Data is Turned Off for streaming", message: "To enable it please go to settings.", preferredStyle: UIAlertControllerStyle.Alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { (action: UIAlertAction!) in }))
            errorAlert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action: UIAlertAction!) in
                let settings = self.storyboard!.instantiateViewControllerWithIdentifier("SettingsTableViewController") as! SettingsTableViewController
                self.navigationController!.pushViewController(settings, animated: true)
            }))
            self.presentViewController(errorAlert, animated: true, completion: nil)
        }
    }
    
    func loadMovieTorrent(media: PCTMovie, onChromecast: Bool = GCKCastContext.sharedInstance().castState == .Connected) {
        let loadingViewController = storyboard!.instantiateViewControllerWithIdentifier("LoadingViewController") as! LoadingViewController
        loadingViewController.transitioningDelegate = self
        loadingViewController.backgroundImage = backgroundImageView.image
        presentViewController(loadingViewController, animated: true, completion: nil)
        let magnet = makeMagnetLink(currentItem.currentTorrent.hash!)
        let moviePlayer = self.storyboard!.instantiateViewControllerWithIdentifier("PCTPlayerViewController") as! PCTPlayerViewController
        let currentProgress = WatchlistManager.movieManager.currentProgress(currentItem.imdbId)
        PTTorrentStreamer.sharedStreamer().startStreamingFromFileOrMagnetLink(magnet, progress: { (status) in
            loadingViewController.progress = status.bufferingProgress
            loadingViewController.speed = Int(status.downloadSpeed)
            loadingViewController.seeds = Int(status.seeds)
            loadingViewController.updateProgress()
            moviePlayer.bufferProgressView?.progress = status.totalProgreess
            }, readyToPlay: { (videoFileURL, videoFilePath) in
                loadingViewController.dismissViewControllerAnimated(false, completion: nil)
                if onChromecast {
                    let castMetadata = PCTCastMetaData(movie: media, subtitle: media.currentSubtitle, duration: NSTimeInterval(media.runtime * 60), startPosition: NSTimeInterval(currentProgress), url: videoFileURL.relativeString!)
                    let metadata = GCKMediaMetadata(metadataType: .Movie)
                    metadata.setString(castMetadata.title, forKey: kGCKMetadataKeyTitle)
                    metadata.addImage(GCKImage(URL: castMetadata.imageUrl, width: 480, height: 720))
                    var mediaTrack: GCKMediaTrack?
                    if let subtitle = castMetadata.subtitle {
                        mediaTrack = GCKMediaTrack(identifier: 1, contentIdentifier: subtitle.link, contentType: "text/plain", type: .Text, textSubtype: .Subtitles, name: subtitle.language, languageCode: subtitle.ISO639, customData: nil)
                    }
                    let mediaInfo = GCKMediaInformation(contentID: castMetadata.url, streamType: .Buffered, contentType: castMetadata.contentType, metadata: metadata, streamDuration: castMetadata.duration, mediaTracks: mediaTrack != nil ? [mediaTrack!] : nil, textTrackStyle: GCKMediaTextTrackStyle.createDefault(), customData: nil)
                    GCKCastContext.sharedInstance().sessionManager.currentCastSession!.remoteMediaClient.loadMedia(mediaInfo, autoplay: true, playPosition: castMetadata.startPosition)
                } else {
                    moviePlayer.play(media, fromURL: videoFileURL, progress: currentProgress, directory: videoFilePath.URLByDeletingLastPathComponent!)
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
    
	@IBAction func watchTrailorTapped(sender: AnyObject) {
        let vc = XCDYouTubeVideoPlayerViewController(videoIdentifier: currentItem.trailorURLString)
        presentViewController(vc, animated: true, completion: nil)
	}

	func tablePickerView(tablePickerView: TablePickerView, didChange items: [String]) {
        if items.count == 0 {
            currentItem.currentSubtitle = nil
            subtitlesButton.setTitle("None ▾", forState: .Normal)
        } else {
            for subtitle in currentItem.subtitles! {
                if items[0] == subtitle.link {
                    currentItem.currentSubtitle = subtitle
                    subtitlesButton.setTitle(subtitle.language + " ▾", forState: .Normal)
                }
            }
        }
	}
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presented is LoadingViewController ? PCTLoadingViewAnimatedTransitioning(isPresenting: true, sourceController: source) : nil
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissed is LoadingViewController ? PCTLoadingViewAnimatedTransitioning(isPresenting: false, sourceController: self) : nil
    }
}
