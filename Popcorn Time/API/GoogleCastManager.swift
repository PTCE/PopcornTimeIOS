

import Foundation
import GoogleCast

class GoogleCastManager: NSObject, GCKDeviceScannerListener, GCKSessionManagerListener {
    
    var dataSourceArray = [GCKDevice]()
    weak var delegate: ConnectDevicesProtocol?
    
    var deviceScanner = GCKDeviceScanner(filterCriteria: GCKFilterCriteria(forAvailableApplicationWithID: kGCKMediaDefaultReceiverApplicationID))
    
    /// If a user is connected to a device and wants to connect to another, a queue has to be made as the disconnect operation is asyncronous. When the user has successfully disconnected from the first device, this device should then be connected to.
    private var deviceAwaitingConnection: GCKDevice?
    var castMetadata: PCTCastMetaData?
    
    override init() {
        super.init()
        deviceScanner.addListener(self)
        deviceScanner.startScan()
        GCKCastContext.sharedInstance().sessionManager.addListener(self)
    }
    
    /// If you chose to initialise with this method, no delegate requests will be recieved.
    init(castMetadata: PCTCastMetaData) {
        super.init()
        self.castMetadata = castMetadata
    }
    
    func didSelectRoute(device: GCKDevice, castMetadata: PCTCastMetaData? = nil) {
        self.castMetadata = castMetadata
        if let session = GCKCastContext.sharedInstance().sessionManager.currentSession {
            GCKCastContext.sharedInstance().sessionManager.endSession()
            if session.device != device {
               deviceAwaitingConnection = device
            }
        } else {
            GCKCastContext.sharedInstance().sessionManager.startSessionWithDevice(device)
        }
        delegate?.didConnectToDevice(deviceIsChromecast: true)
    }
    
    // MARK: - GCKDeviceScannerListener
    
    func deviceDidComeOnline(device: GCKDevice) {
        dataSourceArray.append(device)
        delegate?.updateTableView(dataSource: dataSourceArray, updateType: .Insert, indexPaths: [NSIndexPath(forRow: dataSourceArray.count - 1, inSection: 1)])
    }
    

    func deviceDidGoOffline(device: GCKDevice) {
        for (index, oldDevice) in dataSourceArray.enumerate() {
            if device === oldDevice {
                dataSourceArray.removeAtIndex(index)
                delegate?.updateTableView(dataSource: dataSourceArray, updateType: .Delete, indexPaths: [NSIndexPath(forRow: index, inSection: 1)])
            }
        }
    }
    
    func deviceDidChange(device: GCKDevice) {
        for (index, oldDevice) in dataSourceArray.enumerate() {
            if device === oldDevice {
                dataSourceArray[index] = device
                delegate?.updateTableView(dataSource: dataSourceArray, updateType: .Reload, indexPaths: [NSIndexPath(forRow: index, inSection: 1)])
            }
        }
    }
    
    // MARK: - GCKSessionManagerListener
    
    func sessionManager(sessionManager: GCKSessionManager, didEndSession session: GCKSession, withError error: NSError?) {
        guard error == nil else { print(error); return }
        if let device = deviceAwaitingConnection {
            GCKCastContext.sharedInstance().sessionManager.startSessionWithDevice(device)
        }
    }
    
    func sessionManager(sessionManager: GCKSessionManager, didStartSession session: GCKSession) {
        if let castMetadata = castMetadata {
            if let subtitle = castMetadata.subtitle {
                downloadSubtitle(subtitle.link, downloadDirectory: castMetadata.mediaAssetsPath, covertToVTT: true, completion: { subtitlePath in
                    let mediaTrack = GCKMediaTrack(identifier: 1, contentIdentifier: subtitlePath.relativePath!, contentType: "text/vtt", type: .Text, textSubtype: .Subtitles, name: subtitle.language, languageCode: subtitle.ISO639, customData: nil)
                    self.streamToDevice(mediaTrack, sessionManager: sessionManager, castMetadata: castMetadata)
                })
            } else {
                streamToDevice(sessionManager: sessionManager, castMetadata: castMetadata)
            }
        }
    }
    
    func streamToDevice(mediaTrack: GCKMediaTrack? = nil, sessionManager: GCKSessionManager, castMetadata: PCTCastMetaData) {
        let metadata = GCKMediaMetadata(metadataType: .Movie)
        metadata.setString(castMetadata.title, forKey: kGCKMetadataKeyTitle)
        metadata.addImage(GCKImage(URL: castMetadata.imageUrl, width: 480, height: 720))
        let mediaInfo = GCKMediaInformation(contentID: castMetadata.url, streamType: .Buffered, contentType: castMetadata.contentType, metadata: metadata, streamDuration: 0, mediaTracks: nil, textTrackStyle: nil, customData: nil)
        sessionManager.currentCastSession!.remoteMediaClient.loadMedia(mediaInfo, autoplay: true, playPosition: castMetadata.startPosition)
    }

    
    deinit {
        if deviceScanner.scanning {
            deviceScanner.stopScan()
            deviceScanner.removeListener(self)
            GCKCastContext.sharedInstance().sessionManager.removeListener(self)
        }
        deviceAwaitingConnection = nil
        castMetadata = nil
    }
    
}

func == (left: GCKDevice, right: GCKDevice) -> Bool {
    return left.deviceID == right.deviceID && left.uniqueID == right.uniqueID
}

func != (left: GCKDevice, right: GCKDevice) -> Bool {
    return left.deviceID != right.deviceID && left.uniqueID != right.uniqueID
}
