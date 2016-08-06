

import UIKit

class CastIconButton: UIButton {
    
    var status: GCKCastState = .NoDevicesAvailable {
        didSet {
            switch status {
            case .NoDevicesAvailable:
                imageView?.stopAnimating()
                hidden = true
            case .NotConnected:
                hidden = false
                imageView!.stopAnimating()
                setImage(castOff, forState: .Normal)
                tintColor = superview?.tintColor
            case .Connecting:
                hidden = false
                tintColor = superview?.tintColor
                setImage(castOff, forState: .Normal)
                imageView!.startAnimating()
            case .Connected:
                hidden = false
                imageView!.stopAnimating()
                setImage(castOn, forState: .Normal)
                tintColor = UIColor.appColor()
            }
        }
    }
    let castOff = UIImage(named: "CastOff")!
    let castOn = UIImage(named: "CastOn")!
    var castConnecting: [UIImage] {
      return [UIImage(named: "CastOn0")!.withColor(superview?.tintColor), UIImage(named: "CastOn1")!.withColor(superview?.tintColor), UIImage(named: "CastOn2")!.withColor(superview?.tintColor), UIImage(named: "CastOn1")!.withColor(superview?.tintColor)]
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView!.animationImages = castConnecting
        imageView!.animationDuration = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        imageView!.animationImages = castConnecting
        imageView!.animationDuration = 2
    }
}

class CastIconBarButtonItem: UIBarButtonItem {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customView = CastIconButton(frame: CGRectMake(0,0,26,26))
    }
}


