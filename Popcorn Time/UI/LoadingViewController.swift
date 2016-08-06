

import UIKit
import PopcornTorrent
import AlamofireImage

class LoadingViewController: UIViewController {
    
    @IBOutlet private weak var progressLabel: UILabel!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var speedLabel: UILabel!
    @IBOutlet private weak var seedsLabel: UILabel!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var backgroundImageView: UIImageView!

    
    var progress: Float = 0.0
    var speed: Int = 0
    var seeds: Int = 0
    var backgroundImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().idleTimerDisabled = true
        if let backgroundImage = backgroundImage {
            backgroundImageView.image = backgroundImage
        }
    }
    
    func updateProgress() {
        loadingView.hidden = true
        for view in [progressLabel, speedLabel, seedsLabel, progressView] {
            view.hidden = false
        }
        progressView.progress = progress
        progressLabel.text = String(format: "%.0f%%", progress*100)
        speedLabel.text = NSByteCountFormatter.stringFromByteCount(Int64(speed), countStyle: .Binary) + "/s"
        seedsLabel.text = "\(seeds) seeds"
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidLoad()
        UIApplication.sharedApplication().idleTimerDisabled = false
    }

    @IBAction func cancelButtonPressed() {
        PTTorrentStreamer.sharedStreamer().cancelStreaming()
        if NSUserDefaults.standardUserDefaults().boolForKey("removeCacheOnPlayerExit") {
            try! NSFileManager.defaultManager().removeItemAtURL(NSURL(fileURLWithPath: downloadsDirectory))
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
}
