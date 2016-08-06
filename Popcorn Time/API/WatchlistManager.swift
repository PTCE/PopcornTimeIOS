

import Foundation

class WatchlistManager {
    
    private var currentType: TraktTVAPI.type
    /**
     Creates new instance of WatchlistManager class.
     
     - Returns: Fully initialised WatchlistManager class with type of Movies.
     */
    static let movieManager = {
        WatchlistManager(type: .Movies)
    }()
    /**
     Creates new instance of WatchlistManager class.
     
     - Returns: Fully initialised WatchlistManager class with type of Episodes.
     */
    static let episodeManager = {
        WatchlistManager(type: .Episodes)
    }()
    /**
     Creates new instance of WatchlistManager class.
     
     - Returns: Fully initialised WatchlistManager class with type of Shows.
     */
    static let showManager = {
        WatchlistManager(type: .Shows)
    }()
    
    private init(type: TraktTVAPI.type) {
        currentType = type
    }
    
    func toggleWatched(id: String) {
        isWatched(id) ? remove(id): add(id)
    }
    /**
     Adds movie or episode to watchlists and syncs with Trakt.
     
     - Parameter id: The Imdb identification code of the episode or tv.
     */
    func add(id: String) {
        TraktTVAPI.sharedInstance.scrobble(id, progress: 1, type: currentType, status: .Finished)
        var array = NSUserDefaults.standardUserDefaults().objectForKey("Watchlist") as? [String]
        array = array ?? [String]()
        array!.append(id)
        NSUserDefaults.standardUserDefaults().setObject(array, forKey: "Watchlist")
    }
    /**
     Removes movie or episode to watchlists and syncs with Trakt.
     
     - Parameter id: The Imdb identification code of the episode or tv.
     */
    func remove(id: String) {
        TraktTVAPI.sharedInstance.removeItemFromHistory(currentType, id: id)
        if var array = NSUserDefaults.standardUserDefaults().objectForKey("Watchlist") as? [String] {
            for (index, item) in array.enumerate() {
                if item == id {
                    array.removeAtIndex(index)
                }
            }
            NSUserDefaults.standardUserDefaults().setObject(array, forKey: "Watchlist")
        }
    }
    /**
     Checks if movie or episode is in the watchlist.
     
     - Parameter id: The Imdb identification code of the movie or episode.
     
     - Returns: Boolean indicating if movie or episode is in watchlist.
     */
    func isWatched(id: String) -> Bool {
        if let array = NSUserDefaults.standardUserDefaults().objectForKey("Watchlist") as? [String] {
            return array.contains(id)
        }
        return false
    }
    /**
     Gets watchlist locally first and then from Trakt.
     
     - Returns: Completion block called twice; first returns locally stored watchlist (may be out of date), second time returns the updated watchlist from Trakt.
     */
    func getWatched(completion:() -> Void) {
        var array = NSUserDefaults.standardUserDefaults().objectForKey("Watchlist") as? [String]
        array = array ?? [String]()
        completion()
        TraktTVAPI.sharedInstance.getWatched(currentType) { watchedIds in
            array!.removeAll()
            array = watchedIds
            NSUserDefaults.standardUserDefaults().setObject(array, forKey: "Watchlist")
            completion()
        }
    }
    /**
     Gets progress locally first and then from Trakt.
     */
    func getProgress() {
        var progressDict = NSUserDefaults.standardUserDefaults().objectForKey("VideoProgress") as? [String: Float]
        progressDict = progressDict ?? [String: Float]()
        TraktTVAPI.sharedInstance.getPlaybackProgress(currentType) { dict in
            progressDict!.removeAll()
            progressDict = dict
            NSUserDefaults.standardUserDefaults().setObject(progressDict, forKey: "VideoProgress")
        }
    }
    /**
     Gets watched progress for movie or epsiode.
     
     - Parameter id: The Imdb identification code of the movie or episode.
     
     - Returns: The progress (if any) of the movie or episode.
     */
    func currentProgress(id: String) -> Float {
        if let dict = NSUserDefaults.standardUserDefaults().objectForKey("VideoProgress") as? [String: Float],
            let progress = dict[id] {
            return progress
        }
        return 0.0
    }
}
