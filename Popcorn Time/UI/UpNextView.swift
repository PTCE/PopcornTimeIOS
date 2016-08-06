

import UIKit
import SwiftyTimer

protocol UpNextViewDelegate: class {
    func constraintsWereUpdated(willHide hide: Bool)
    func timerFinished()
}

class UpNextView: UIVisualEffectView {
    
    @IBOutlet var nextEpisodeInfoLabel: UILabel!
    @IBOutlet var nextEpisodeTitleLabel: UILabel!
    @IBOutlet var nextShowTitleLabel: UILabel!
    @IBOutlet var nextEpsiodeThumbImageView: UIImageView!
    @IBOutlet var nextEpisodeCountdownLabel: UILabel!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    @IBOutlet var trailingConstraint: NSLayoutConstraint!
    
    weak var delegate: UpNextViewDelegate?
    private var timer: NSTimer!
    private var updateTimer: NSTimer!
    
    func show() {
        if hidden {
            hidden = false
            trailingConstraint.active = false
            leadingConstraint.active = true
            delegate?.constraintsWereUpdated(willHide: false)
            startTimer()
        }
    }
    
    func hide() {
        if !hidden {
            trailingConstraint.active = true
            leadingConstraint.active = false
            delegate?.constraintsWereUpdated(willHide: true)
        }
    }
    
    func startTimer() {
        var delay = 10
        updateTimer = NSTimer.every(1.0) {
            if delay - 1 >= 0 {
                delay -= 1
                self.nextEpisodeCountdownLabel.text = String(delay)
            }
        }
        timer = NSTimer.after(10.0, {
            self.updateTimer.invalidate()
            self.updateTimer = nil
            self.delegate?.timerFinished()
        })
    }
    
    @IBAction func closePlayNextView() {
        hide()
        timer.invalidate()
        timer = nil
    }
    @IBAction func playNextNow() {
        hide()
        updateTimer.invalidate()
        updateTimer = nil
        timer.invalidate()
        timer = nil
        self.delegate?.timerFinished()
    }

}

extension PCTPlayerViewController {
    func constraintsWereUpdated(willHide hide: Bool) {
        UIView.animateWithDuration(animationLength, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: { (finished) in
                if hide {
                   self.upNextView.hidden = true
                }
        })
    }
    
    func timerFinished() {
        didFinishPlaying()
        delegate?.playNext(nextMedia!)
    }
}
