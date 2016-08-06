

import UIKit
import MediaPlayer
import GoogleCast

class StreamToDevicesTableViewController: UITableViewController, GCKDeviceScannerListener, ConnectDevicesProtocol {
    
    var airPlayDevices = [MPAVRouteProtocol]()
    var googleCastDevices = [GCKDevice]()
    
    var airPlayManager: AirPlayManager!
    var googleCastManager: GoogleCastManager!
    
    var onlyShowCastDevices: Bool = false
    var castMetadata: PCTCastMetaData?
    
    
    override func viewDidLoad() {
        if !onlyShowCastDevices {
            airPlayManager = AirPlayManager()
            airPlayManager.delegate = self
        }
        googleCastManager = GoogleCastManager()
        googleCastManager.delegate = self
    }
    
    @IBAction func mirroringChanged(sender: UISwitch) {
        let selectedRoute = airPlayDevices[tableView.indexPathForCell(sender.superview?.superview as! AirPlayTableViewCell)!.row]
        airPlayManager.mirrorChanged(sender, selectedRoute: selectedRoute)
    }
    
    func updateTableView(dataSource newDataSource: [AnyObject], updateType: TableViewUpdates, indexPaths: [NSIndexPath]?) {
        self.tableView.beginUpdates()
        if let dataSource = newDataSource as? [GCKDevice] {
            googleCastDevices = dataSource
        } else {
            airPlayDevices = newDataSource as! [MPAVRouteProtocol]
        }
        switch updateType {
        case .Insert:
            self.tableView.insertRowsAtIndexPaths(indexPaths!, withRowAnimation: .Middle)
            fallthrough
        case .Reload:
            if let visibleIndexPaths = self.tableView.indexPathsForVisibleRows {
                self.tableView.reloadRowsAtIndexPaths(visibleIndexPaths, withRowAnimation: .None)
            }
        case .Delete:
            self.tableView.deleteRowsAtIndexPaths(indexPaths!, withRowAnimation: .Middle)
        }
        self.tableView.endUpdates()
    }
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if airPlayDevices.isEmpty && googleCastDevices.isEmpty {
            let label = UILabel(frame: CGRectMake(0,0,100,100))
            label.text = "No devices available"
            label.textColor = UIColor.lightGrayColor()
            label.numberOfLines = 0
            label.textAlignment = .Center
            label.sizeToFit()
            tableView.backgroundView = label
            tableView.separatorStyle = .None
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .SingleLine
        }
        return 2
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return airPlayDevices.isEmpty ? nil : "AirPlay"
        case 1:
            return googleCastDevices.isEmpty ? nil : "Google Cast"
        default:
            return nil
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? airPlayDevices.count : googleCastDevices.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! AirPlayTableViewCell
        if indexPath.section == 0 {
            cell.picked = airPlayDevices[indexPath.row].isPicked!()
            if let mirroringRoute = airPlayDevices[indexPath.row].wirelessDisplayRoute?() where mirroringRoute.isPicked!() {
                cell.picked = true
                cell.mirrorSwitch?.setOn(true, animated: true)
            } else {
                cell.mirrorSwitch?.setOn(false, animated: false)
            }
            cell.titleLabel?.text = airPlayDevices[indexPath.row].routeName!()
            cell.airImageView?.image = airPlayManager.airPlayItemImage(indexPath.row)
        } else {
            cell.titleLabel?.text = googleCastDevices[indexPath.row].friendlyName
            cell.airImageView?.image = UIImage(named: "CastOff")
            if let session = GCKCastContext.sharedInstance().sessionManager.currentSession {
                cell.picked = googleCastDevices[indexPath.row] == session.device
            } else {
                cell.picked = false
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            airPlayManager.didSelectRoute(airPlayDevices[indexPath.row])
        } else {
            googleCastManager.didSelectRoute(googleCastDevices[indexPath.row], castMetadata: castMetadata)
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && airPlayDevices.isEmpty {
            return CGFloat.min
        } else if section == 1 && googleCastDevices.isEmpty {
            return CGFloat.min
        }
        return 18
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if let _ = airPlayDevices[indexPath.row].wirelessDisplayRoute?() where airPlayDevices[indexPath.row].isPicked!() || airPlayDevices[indexPath.row].wirelessDisplayRoute!().isPicked!() {
                return 88
            }
        }
        return 44
    }
    
    func didConnectToDevice(deviceIsChromecast chromecast: Bool) {
        if chromecast && presentingViewController is PCTPlayerViewController {
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: presentCastPlayerNotification, object: nil))
        } else {
           dismissViewControllerAnimated(true, completion: nil)
        }
    }
}
