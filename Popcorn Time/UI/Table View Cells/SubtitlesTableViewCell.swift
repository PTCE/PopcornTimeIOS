

import UIKit

class SubtitlesTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var checkmarkAccessory: UIButton?
    var currentSubtitle: String! {
        didSet {
            self.checkmarkAccessory?.hidden = true
            self.titleLabel?.textColor = UIColor.blackColor()
            if let subtitle = NSUserDefaults.standardUserDefaults().objectForKey("currentSubtitle") as? String {
                if currentSubtitle == subtitle {
                    self.checkmarkAccessory?.hidden = false
                    self.titleLabel?.textColor = superview?.tintColor
                }
            }
        }
    }

}
