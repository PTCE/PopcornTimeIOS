

import UIKit

class CoverCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var watchedIndicator: UIView?
    var watched: Bool = false {
        didSet {
            if let watchedIndicator = watchedIndicator {
                UIView.animateWithDuration(0.25, animations: {
                    if self.watched {
                        watchedIndicator.alpha = 0.5
                        watchedIndicator.hidden = false
                    } else {
                        watchedIndicator.alpha = 0.0
                        watchedIndicator.hidden = true
                    }
                })
            }
        }
    }
}
