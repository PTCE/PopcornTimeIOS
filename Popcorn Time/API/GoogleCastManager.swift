

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
        delegate?.didConnectToDevice()
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
            let metadata = GCKMediaMetadata(metadataType: .Movie)
            metadata.setString(castMetadata.title, forKey: kGCKMetadataKeyTitle)
            metadata.addImage(GCKImage(URL: castMetadata.imageUrl, width: 480, height: 720))
            var mediaTrack: GCKMediaTrack?
            if let subtitle = castMetadata.subtitle {
                mediaTrack = GCKMediaTrack(identifier: 1, contentIdentifier: subtitle.link, contentType: "text/vtt", type: .Text, textSubtype: .Subtitles, name: subtitle.language, languageCode: subtitle.ISO639, customData: nil)
            }
            let mediaInfo = GCKMediaInformation(contentID: castMetadata.url, streamType: .Buffered, contentType: castMetadata.contentType, metadata: metadata, streamDuration: castMetadata.duration, mediaTracks: mediaTrack != nil ? [mediaTrack!] : nil, textTrackStyle: GCKMediaTextTrackStyle.createDefault(), customData: nil)
            sessionManager.currentCastSession!.remoteMediaClient.loadMedia(mediaInfo, autoplay: true, playPosition: castMetadata.startPosition)
        }
    }

    
    deinit {
        deviceScanner.stopScan()
        deviceScanner.removeListener(self)
        GCKCastContext.sharedInstance().sessionManager.removeListener(self)
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
