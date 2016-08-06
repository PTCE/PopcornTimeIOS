

import Foundation
import MediaPlayer


enum TableViewUpdates {
    case Reload
    case Insert
    case Delete
}

protocol ConnectDevicesProtocol: class {
    func updateTableView(dataSource newDataSource: [AnyObject], updateType: TableViewUpdates, indexPaths: [NSIndexPath]?)
    func didConnectToDevice()
}

class AirPlayManager: NSObject {
    
    var dataSourceArray = [MPAVRouteProtocol]()
    weak var delegate: ConnectDevicesProtocol?
    
    let MPAudioDeviceControllerClass: NSObject.Type =  NSClassFromString("MPAudioDeviceController") as! NSObject.Type
    let MPAVRoutingControllerClass: NSObject.Type = NSClassFromString("MPAVRoutingController") as! NSObject.Type
    var routingController: MPAVRoutingControllerProtocol
    var audioDeviceController: MPAudioDeviceControllerProtocol
    
    override init() {
        routingController = MPAVRoutingControllerClass.init() as MPAVRoutingControllerProtocol
        audioDeviceController = MPAudioDeviceControllerClass.init() as MPAudioDeviceControllerProtocol
        super.init()
        audioDeviceController.setRouteDiscoveryEnabled!(true)
        routingController.setDelegate!(self)
        updateAirPlayDevices()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateAirPlayDevices), name: MPVolumeViewWirelessRouteActiveDidChangeNotification, object: nil)
    }
    
    func mirrorChanged(sender: UISwitch, selectedRoute: MPAVRouteProtocol) {
        if sender.on {
            routingController.pickRoute!(selectedRoute.wirelessDisplayRoute!())
        } else {
            routingController.pickRoute!(selectedRoute)
        }
    }
    
    func updateAirPlayDevices() {
        routingController.fetchAvailableRoutesWithCompletionHandler! { (routes) in
            if routes.count > self.dataSourceArray.count {
                var indexPaths = [NSIndexPath]()
                for index in self.dataSourceArray.count..<routes.count {
                    indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
                }
                self.dataSourceArray = routes
                self.delegate?.updateTableView(dataSource: self.dataSourceArray, updateType: .Insert, indexPaths: indexPaths)
            } else if routes.count < self.dataSourceArray.count {
                var indexPaths = [NSIndexPath]()
                for (index, route) in self.dataSourceArray.enumerate() {
                    if !routes.contains({ $0.routeUID!() == route.routeUID!() }) // If the new array doesn't contain an object in the old array it must have been removed
                    {
                        indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
                    }
                }
                self.dataSourceArray = routes
                self.delegate?.updateTableView(dataSource: self.dataSourceArray, updateType: .Delete, indexPaths: indexPaths)
            } else {
                self.dataSourceArray = routes
                self.delegate?.updateTableView(dataSource: self.dataSourceArray, updateType: .Reload, indexPaths: nil)
            }
        }
    }
    
    func airPlayItemImage(row: Int) -> UIImage {
        if let routeType = self.audioDeviceController.routeDescriptionAtIndex!(row)["AirPlayPortExtendedInfo"]?["model"] as? String {
            if routeType.containsString("AppleTV") {
                return UIImage(named: "AirTV")!
            } else {
                return UIImage(named: "AirSpeaker")!
            }
        } else {
            return UIImage(named: "AirAudio")!
        }
    }
    
    func didSelectRoute(selectedRoute: MPAVRouteProtocol) {
        self.routingController.pickRoute!(selectedRoute)
    }
    
    // MARK: - MPAVRoutingControllerDelegate
    
    func routingControllerAvailableRoutesDidChange(controller: MPAVRoutingControllerProtocol) {
        updateAirPlayDevices()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        audioDeviceController.setRouteDiscoveryEnabled!(false)
    }
}

// MARK: - MPProtocols

@objc protocol MPAVRoutingControllerProtocol {
    optional func availableRoutes() -> NSArray
    optional func discoveryMode() -> Int
    optional func fetchAvailableRoutesWithCompletionHandler(completion: (routes: [MPAVRouteProtocol]) -> Void)
    optional func name() -> AnyObject
    optional func pickRoute(route: MPAVRouteProtocol) -> Bool
    optional func pickRoute(route: MPAVRouteProtocol, withPassword: String) -> Bool
    optional func videoRouteForRoute(route: MPAVRouteProtocol) -> MPAVRouteProtocol
    optional func clearCachedRoutes()
    optional func setDelegate(delegate: NSObject)
}

@objc protocol MPAVRouteProtocol {
    optional func routeName() -> String
    optional func routeSubtype() -> Int
    optional func routeType() -> Int
    optional func requiresPassword() -> Bool
    optional func routeUID() -> String
    optional func isPicked() -> Bool
    optional func passwordType() -> Int
    optional func wirelessDisplayRoute() -> MPAVRouteProtocol
    
}

@objc protocol MPAudioDeviceControllerProtocol {
    optional func setRouteDiscoveryEnabled(enabled: Bool)
    optional func routeDescriptionAtIndex(index: Int) -> [String: AnyObject]
}

extension NSObject : MPAVRoutingControllerProtocol, MPAVRouteProtocol, MPAudioDeviceControllerProtocol {
    
}