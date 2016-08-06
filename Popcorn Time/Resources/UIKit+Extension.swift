

import UIKit
import OBSlider
import MediaPlayer


// MARK: - UIView

@IBDesignable class GradientView: UIView {
    
    @IBInspectable var topColor: UIColor? {
        didSet {
            configureView()
        }
    }
    @IBInspectable var bottomColor: UIColor? {
        didSet {
            configureView()
        }
    }
    
    override class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        configureView()
    }
    
    func configureView() {
        let layer = self.layer as! CAGradientLayer
        let locations = [ 0.0, 1.0 ]
        layer.locations = locations
        let color1 = topColor ?? self.tintColor as UIColor
        let color2 = bottomColor ?? UIColor.blackColor() as UIColor
        let colors: Array <AnyObject> = [ color1.CGColor, color2.CGColor ]
        layer.colors = colors
    }
    
}


@IBDesignable class CircularView: UIView {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.CGColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension UIView {
    /**
     Remove all constraints from the view.
     */
    func removeConstraints() {
        if let superview = self.superview {
            for constraint in superview.constraints {
                if constraint.firstItem as? UIView == self || constraint.secondItem as? UIView == self {
                    constraint.active = false
                }
            }
        }
        for constraint in constraints {
            constraint.active = false
        }
    }
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.nextResponder()
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

// MARK: - UIButton

@IBDesignable class PCTBorderButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.CGColor
            tintColor = borderColor
            setTitleColor(borderColor, forState: .Normal)
        }
    }
    override var highlighted: Bool {
        didSet {
            updateColor(highlighted)
        }
    }
    
    func updateColor(tint: Bool) {
        UIView.animateWithDuration(0.25) {
            if tint {
                self.backgroundColor =  self.borderColor ?? UIColor(red:0.37, green:0.41, blue:0.91, alpha:1.0)
                self.setTitleColor(UIColor.whiteColor(), forState: .Highlighted)
            } else {
                self.backgroundColor = UIColor.clearColor()
                self.setTitleColor(self.borderColor ?? UIColor(red:0.37, green:0.41, blue:0.91, alpha:1.0), forState: .Normal)
            }
        }
    }
}

@IBDesignable class PCTBlurButton: UIButton {
    var cornerRadius: CGFloat = 0.0 {
        didSet {
            backgroundView.layer.cornerRadius = cornerRadius
            backgroundView.layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var blurTint: UIColor = UIColor.clearColor() {
        didSet {
            backgroundView.contentView.backgroundColor = blurTint
        }
    }
    var blurStyle: UIBlurEffectStyle = .Light {
        didSet {
            backgroundView.effect = UIBlurEffect(style: blurStyle)
        }
    }
    
    private var backgroundView: UIVisualEffectView
    
    override init(frame: CGRect) {
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        super.init(frame: frame)
        setUpButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        super.init(coder: aDecoder)
        setUpButton()
    }
    
    func setUpButton() {
        backgroundView.frame = bounds
        backgroundView.userInteractionEnabled = false
        addSubview(backgroundView)
        sendSubviewToBack(backgroundView)
        let imageView = UIImageView(image: self.imageView!.image)
        imageView.frame = self.imageView!.bounds
        imageView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        imageView.userInteractionEnabled = false
        self.imageView?.removeFromSuperview()
        addSubview(imageView)
        imageView.transform = CGAffineTransformMakeScale(0.5, 0.5)
    }
    
    override var highlighted: Bool {
        didSet {
            updateColor(highlighted)
        }
    }
    
    func updateColor(tint: Bool) {
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { 
            self.backgroundView.contentView.backgroundColor = tint ? UIColor.whiteColor() : self.blurTint
            }, completion: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cornerRadius = bounds.width/2
    }
}

@IBDesignable class PCTHighlightedImageButton: UIButton {
    @IBInspectable var highlightedImageTintColor: UIColor = UIColor.whiteColor()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setImage(self.imageView?.image?.withColor(highlightedImageTintColor), forState: .Highlighted)
    }
    
    override func setImage(image: UIImage?, forState state: UIControlState) {
        super.setImage(image, forState: state)
        super.setImage(image?.withColor(highlightedImageTintColor), forState: .Highlighted)
    }
}



// MARK: - String

func randomString(length length: Int) -> String {
    let alphabet = "-_1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    let upperBound = UInt32(alphabet.characters.count)
    return String((0..<length).map { _ -> Character in
        return alphabet[alphabet.startIndex.advancedBy(Int(arc4random_uniform(upperBound)))]
        })
}

let downloadsDirectory: String = {
    let cachesPath = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)[0]
    let downloadsDirectoryPath = cachesPath.URLByAppendingPathComponent("Downloads")
    if !NSFileManager.defaultManager().fileExistsAtPath(downloadsDirectoryPath.relativePath!) {
        try! NSFileManager.defaultManager().createDirectoryAtPath(downloadsDirectoryPath.relativePath!, withIntermediateDirectories: true, attributes: nil)
    }
    return downloadsDirectoryPath.relativePath!
}()

extension String {
    func urlStringValues() -> [String: String] {
        var queryStringDictionary = [String: String]()
        let urlComponents = componentsSeparatedByString("&")
        for keyValuePair in urlComponents {
            let pairComponents = keyValuePair.componentsSeparatedByString("=")
            let key = pairComponents.first?.stringByRemovingPercentEncoding
            let value = pairComponents.last?.stringByRemovingPercentEncoding
            queryStringDictionary[key!] = value!
        }
        return queryStringDictionary
    }
    
    func sliceFrom(start: String, to: String) -> String? {
        return (rangeOfString(start)?.endIndex).flatMap { sInd in
            let eInd = rangeOfString(to, range: sInd..<endIndex)
            if eInd != nil {
                return (eInd?.startIndex).map { eInd in
                    return substringWithRange(sInd..<eInd)
                }
            }
            return substringWithRange(sInd..<endIndex)
        }
    }
}

// MARK: - Dictionary

extension Dictionary {
    
    func filter(predicate: Element -> Bool) -> Dictionary {
        var filteredDictionary = Dictionary()
        
        for (key, value) in self {
            if predicate(key, value) {
                filteredDictionary[key] = value
            }
        }
        
        return filteredDictionary
    }
    
}

extension Dictionary where Value : Equatable {
    func allKeysForValue(val : Value) -> [Key] {
        return self.filter { $1 == val }.map { $0.0 }
    }
}

func += <K, V> (inout left: [K:V], right: [K:V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

// MARK: - NSLocale


extension NSLocale {
    
    private static var langs: NSDictionary {
        get {
            return [
                "af": "Afrikaans",
                "sq": "Albanian",
                "ar": "Arabic",
                "hy": "Armenian",
                "at": "Asturian",
                "az": "Azerbaijani",
                "eu": "Basque",
                "be": "Belarusian",
                "bn": "Bengali",
                "bs": "Bosnian",
                "br": "Breton",
                "bg": "Bulgarian",
                "my": "Burmese",
                "ca": "Catalan",
                "zh": "Chinese (simplified)",
                "zt": "Chinese (traditional)",
                "ze": "Chinese bilingual",
                "hr": "Croatian",
                "cs": "Czech",
                "da": "Danish",
                "nl": "Dutch",
                "en": "English",
                "eo": "Esperanto",
                "et": "Estonian",
                "ex": "Extremaduran",
                "fi": "Finnish",
                "fr": "French",
                "ka": "Georgian",
                "gl": "Galician",
                "de": "German",
                "el": "Greek",
                "he": "Hebrew",
                "hi": "Hindi",
                "hu": "Hungarian",
                "it": "Italian",
                "is": "Icelandic",
                "id": "Indonesian",
                "ja": "Japanese",
                "kk": "Kazakh",
                "km": "Khmer",
                "ko": "Korean",
                "lv": "Latvian",
                "lt": "Lithuanian",
                "lb": "Luxembourgish",
                "ml": "Malayalam",
                "ms": "Malay",
                "ma": "Manipuri",
                "mk": "Macedonian",
                "me": "Montenegrin",
                "mn": "Mongolian",
                "no": "Norwegian",
                "oc": "Occitan",
                "fa": "Persian",
                "pl": "Polish",
                "pt": "Portuguese",
                "pb": "Portuguese (BR)",
                "pm": "Portuguese (MZ)",
                "ru": "Russian",
                "ro": "Romanian",
                "sr": "Serbian",
                "si": "Sinhalese",
                "sk": "Slovak",
                "sl": "Slovenian",
                "es": "Spanish",
                "sw": "Swahili",
                "sv": "Swedish",
                "sy": "Syriac",
                "ta": "Tamil",
                "te": "Telugu",
                "tl": "Tagalog",
                "th": "Thai",
                "tr": "Turkish",
                "uk": "Ukrainian",
                "ur": "Urdu",
                "vi": "Vietnamese",
            ]
        }
    }
    
    static func commonISOLanguageCodes() -> [String] {
        return langs.allKeys as! [String]
    }
    
    static func commonLanguages() -> [String] {
        return langs.allValues as! [String]
    }
}

// MARK: - UITableViewCell

extension UITableViewCell {
    func relatedTableView() -> UITableView {
        if let superview = self.superview as? UITableView {
            return superview
        } else if let superview = self.superview?.superview as? UITableView {
            return superview
        } else {
            fatalError("UITableView shall always be found.")
        }
    }
    
    // Fixes multiple color bugs in iPads because of interface builder
    public override var backgroundColor: UIColor? {
        get {
            return backgroundView?.backgroundColor
        }
        set {
            backgroundView?.backgroundColor = backgroundColor
        }
    }
}


// MARK: - UIStoryboardSegue

class DismissSegue: UIStoryboardSegue {
    override func perform() {
        sourceViewController.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - UIImage

extension UIImage {

    func crop(rect: CGRect) -> UIImage {
        var rect = rect
        if self.scale > 1.0 {
            rect = CGRectMake(rect.origin.x * self.scale,
                              rect.origin.y * self.scale,
                              rect.size.width * self.scale,
                              rect.size.height * self.scale)
        }
        
        let imageRef = CGImageCreateWithImageInRect(self.CGImage, rect)
        return UIImage(CGImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
    }
    
    func withColor(color: UIColor?) -> UIImage {
        var color: UIColor! = color
        color = color ?? UIColor.appColor()
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.mainScreen().scale)
        let context = UIGraphicsGetCurrentContext()
        color.setFill()
        CGContextTranslateCTM(context, 0, self.size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextSetBlendMode(context, CGBlendMode.ColorBurn)
        let rect = CGRectMake(0, 0, self.size.width, self.size.height)
        CGContextDrawImage(context, rect, self.CGImage)
        CGContextSetBlendMode(context, CGBlendMode.SourceIn)
        CGContextAddRect(context, rect)
        CGContextDrawPath(context, CGPathDrawingMode.Fill)
        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return coloredImage
    }

}

// MARK: - NSFileManager

extension NSFileManager {
    func fileSizeAtPath(path: String) -> Int64 {
        do {
            let fileAttributes = try attributesOfItemAtPath(path)
            let fileSizeNumber = fileAttributes[NSFileSize]
            let fileSize = fileSizeNumber?.longLongValue
            return fileSize!
        } catch {
            print("error reading filesize, NSFileManager extension fileSizeAtPath")
            return 0
        }
    }
    
    func folderSizeAtPath(path: String) -> Int64 {
        var size : Int64 = 0
        do {
            let files = try subpathsOfDirectoryAtPath(path)
            for i in 0 ..< files.count {
                size += fileSizeAtPath((path as NSString).stringByAppendingPathComponent(files[i]) as String)
            }
        } catch {
            print("Error reading directory.")
        }
        return size
    }
}

// MARK: - UISlider

class PCTBarSlider: OBSlider {
    
    override func trackRectForBounds(bounds: CGRect) -> CGRect {
        var customBounds = super.trackRectForBounds(bounds)
        customBounds.size.height = 3
        customBounds.origin.y -= 1
        return customBounds
    }
    
    override func awakeFromNib() {
        self.setThumbImage(UIImage(named: "Scrubber Image"), forState: .Normal)
        super.awakeFromNib()
    }
}

// MARK: - Magnets

func makeMagnetLink(torrHash: String) -> String {
    let trackers = [
        "udp://tracker.opentrackr.org:1337/announce",
        "udp://glotorrents.pw:6969/announce",
        "udp://torrent.gresille.org:80/announce",
        "udp://tracker.openbittorrent.com:80",
        "udp://tracker.coppersurfer.tk:6969",
        "udp://tracker.leechers-paradise.org:6969",
        "udp://p4p.arenabg.ch:1337",
        "udp://tracker.internetwarriors.net:1337",
        "udp://open.demonii.com:80",
        "udp://tracker.coppersurfer.tk:80",
        "udp://tracker.leechers-paradise.org:6969",
        "udp://exodus.desync.com:6969"
    ]
    let magnetURL = "magnet:?xt=urn:btih:\(torrHash)&tr=" + trackers.joinWithSeparator("&tr=")
    return magnetURL
}

func cleanMagnet(url: String) -> String {
    var hash: String
    if !url.isEmpty {
        if url.containsString("&dn=") {
            hash = url.sliceFrom("magnet:?xt=urn:btih:", to: "&dn=")!
        } else {
            hash = url.sliceFrom("magnet:?xt=urn:btih:", to: "")!
        }
        return makeMagnetLink(hash)
    }
    
    return url
}

// MARK: - UITableView

extension UITableView {
    func sizeHeaderToFit() {
        if let header = tableHeaderView {
            header.setNeedsLayout()
            header.layoutIfNeeded()
            let height = header.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            var frame = header.frame
            frame.size.height = height
            header.frame = frame
            tableHeaderView = header
        }
    }
}

// MARK: - CGSize

extension CGSize {
    static let max = CGSizeMake(CGFloat.max, CGFloat.max)
}

// MARK: - UIViewController

extension UIViewController {
    func fixIOS9PopOverAnchor(segue: UIStoryboardSegue?)
    {
        if let popOver = segue?.destinationViewController.popoverPresentationController,
            let anchor  = popOver.sourceView
            where popOver.sourceRect == CGRect()
                && segue!.sourceViewController === self
        { popOver.sourceRect = anchor.bounds }
    }
    func fixPopOverAnchor(controller: UIAlertController)
    {
        if let popOver = controller.popoverPresentationController,
            let anchor = popOver.sourceView
            where popOver.sourceRect == CGRect()
        { popOver.sourceRect = anchor.bounds }
    }
    
    func statusBarHeight() -> CGFloat {
        let statusBarSize = UIApplication.sharedApplication().statusBarFrame.size
        return Swift.min(statusBarSize.width, statusBarSize.height)
    }
}

extension UIScrollView {
    var isAtTop: Bool {
        return contentOffset.y <= verticalOffsetForTop
    }
    
    var isAtBottom: Bool {
        return contentOffset.y >= verticalOffsetForBottom
    }
    
    var verticalOffsetForTop: CGFloat {
        let topInset = contentInset.top
        return -topInset
    }
    
    var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = bounds.height
        let scrollContentSizeHeight = contentSize.height
        let bottomInset = contentInset.bottom
        let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
        return scrollViewBottomOffset
    }
}

// MARK: - NSUserDefaults

extension NSUserDefaults {
    func reset() {
        for key in dictionaryRepresentation().keys {
            removeObjectForKey(key)
        }
    }
}

// MARK: - UIColor 

extension UIColor {
    class func appColor() -> UIColor {
        return UIColor(red:0.37, green:0.41, blue:0.91, alpha:1.0)
    }
}