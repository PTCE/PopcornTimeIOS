

import UIKit

class GenresTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var checkmarkAccessory: UIButton?
    
    var selectedRow: Int!
    var currentRow: Int! {
        didSet {
            if currentRow == selectedRow {
                self.checkmarkAccessory?.hidden = false
                self.titleLabel?.textColor = superview?.tintColor
            } else {
                self.checkmarkAccessory?.hidden = true
                self.titleLabel?.textColor = UIColor.whiteColor()
            }
        }
    }
}
