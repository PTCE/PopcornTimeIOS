

import UIKit
import PopcornTorrent
import GoogleCast

class CastPlayerViewController: UIViewController, GCKSessionManagerListener {
    
    @IBOutlet var progressSlider: PCTProgressSlider!
    @IBOutlet var volumeSlider: UISlider!
    @IBOutlet var closeButton: PCTBlurButton!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var elapsedTimeLabel: UILabel!
    @IBOutlet var remainingTimeLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var playPauseButton: UIButton!
    
    private var classContext = 0
    
    var backgroundImage: UIImage?
    
    private var remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession!.remoteMediaClient
    private var streamPosition: NSTimeInterval {
        get {
            return remoteMediaClient.mediaStatus!.streamPosition
        } set {
            remoteMediaClient.seekToTimeInterval(newValue)
        }
    }
    private var state: GCKMediaPlayerState {
        return remoteMediaClient.mediaStatus!.playerState
    }
    private var idleReason: GCKMediaPlayerIdleReason {
        return remoteMediaClient.mediaStatus!.idleReason
    }
    private var streamDuration: NSTimeInterval {
        return remoteMediaClient.mediaStatus!.mediaInformation!.streamDuration
    }
    private var elapsedTime: VLCTime {
        return VLCTime(number: NSNumber(double: streamPosition))
    }
    private var remainingTime: VLCTime {
        return VLCTime(number: NSNumber(double: streamPosition - streamDuration))
    }
    
    
    @IBAction func playPause(sender: UIButton) {
        if state == .Paused {
            remoteMediaClient.play()
        } else if state == .Playing {
            remoteMediaClient.pause()
        }
    }
    
    @IBAction func rewind() {
        streamPosition -= 30
    }
    
    @IBAction func fastForward() {
        streamPosition += 30
    }
    
    @IBAction func subtitles() {
        // Change subtitle shit on the fly with setTextTrackStyle
    }
    
    @IBAction func volumeSliderAction() {
        remoteMediaClient.setStreamVolume(volumeSlider.value)
    }
    
    @IBAction func progressSliderAction() {
        streamPosition += (NSTimeInterval(progressSlider.value) * streamDuration)
    }
    
    @IBAction func progressSliderDrag() {
        elapsedTimeLabel.text = VLCTime(number: NSNumber(double: (NSTimeInterval(progressSlider.value) * streamDuration))).stringValue
        remainingTimeLabel.text = VLCTime(number: NSNumber(double: ((NSTimeInterval(progressSlider.value) * streamDuration) - streamDuration))).stringValue
    }
    
    @IBAction func close() {
        dismissViewControllerAnimated(true, completion: nil)
        remoteMediaClient.stop()
        PTTorrentStreamer.sharedStreamer().cancelStreaming()
        if NSUserDefaults.standardUserDefaults().boolForKey("removeCacheOnPlayerExit") {
            // try! NSFileManager.defaultManager().removeItemAtURL(directory)
        }
    }
    
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &classContext,  let newValue = change?[NSKeyValueChangeNewKey]{
            if keyPath == "playerState" {
                // TODO: Trakt
                switch state {
                case .Paused:
                    playPauseButton.setImage(UIImage(named: "Play"), forState: .Normal)
                case .Playing:
                    playPauseButton.setImage(UIImage(named: "Pause"), forState: .Normal)
                case .Buffering:
                    playPauseButton.setImage(UIImage(named: "Play"), forState: .Normal)
                // TODO: Buffering UI
                case .Idle:
                    switch idleReason {
                    case .None:
                        break
                    default:
                        close()
                    }
                default:
                    break
                }
            } else if keyPath == "streamPosition" {
                progressSlider.value = Float(streamPosition)
                remainingTimeLabel.text = remainingTime.stringValue
                elapsedTimeLabel.text = elapsedTime.stringValue
            } else if keyPath == "volume" {
                volumeSlider.value = remoteMediaClient.mediaStatus!.volume
            } else if keyPath == "mediaStatus" {
                if let status = remoteMediaClient.mediaStatus {
                    defer {
                        remoteMediaClient.removeObserver(self, forKeyPath: "mediaStatus")
                        status.addObserver(self, forKeyPath: "playerState", options: .New, context: &classContext)
                        status.addObserver(self, forKeyPath: "streamPosition", options: .New, context: &classContext)
                        status.addObserver(self, forKeyPath: "volume", options: .New, context: &classContext)
                    }
                    volumeSlider.setValue(status.volume, animated: true)
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        remoteMediaClient.addObserver(self, forKeyPath: "mediaStatus", options: .New, context: &classContext)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let image = backgroundImage {
            imageView.image = image
        }
        titleLabel.text = title
        volumeSlider.setThumbImage(UIImage(named: "Scrubber Image"), forState: .Normal)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    deinit {
        remoteMediaClient.mediaStatus?.removeObserver(self, forKeyPath: "playerState")
        remoteMediaClient.mediaStatus?.removeObserver(self, forKeyPath: "streamPosition")
        remoteMediaClient.mediaStatus?.removeObserver(self, forKeyPath: "volume")
    }

}
