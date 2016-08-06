

import Foundation
import Alamofire
import SwiftyJSON

class TraktTVAPI {
    /**
     Creates new instance of TraktTVAPI class.
     
     - Returns: Fully initialised TraktTVAPI class.
     */
    static let sharedInstance = TraktTVAPI()
    /**
     Possible values used in API call.
     */
    enum type: String {
        case Movies = "movies"
        case Shows = "shows"
        case Episodes = "episodes"
        case Animes = "animes"
    }
    /**
     Possible values used in API call.
     */
    enum status: String {
        /**
         When the video intially starts playing or is unpaused.
         */
        case Watching = "start"
        /**
         When the video is paused.
         */
        case Paused = "pause"
        /**
         When the video is stopped or finishes playing on its own.
         */
        case Finished = "stop"
    }
    
    let clientId = "a3b34d7ce9a7f8c1bb216eed6c92b11f125f91ee0e711207e1030e7cdc965e19"
    let clientSecret = "22afa0081bea52793740395c6bc126d15e1f72b0bfb89bbd5729310079f1a01c"
    /**
     Load movie metadata from API.
     
     - Parameter imbd: The imbd identification code used to lookup the movie.
     
     - Returns: The background art URL of the provided movie as a string.
     */
    func getMovieMeta(imdb: String, completion: (backgroundImageAsString: String) -> Void) {
        Alamofire.request(.GET, "https://api.trakt.tv/movies/\(imdb)", parameters: ["extended": "images"], headers: ["trakt-api-key": clientId, "trakt-api-version": "2"]).validate().responseJSON { response in
            guard response.result.isFailure else {
                let responseDict = JSON(response.result.value!)
                var image: String
                if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
                    image = responseDict["images"]["poster"]["medium"].string!
                } else {
                    image = responseDict["images"]["poster"]["full"].string!
                }
                completion(backgroundImageAsString: image)
                return
            }
        }
    }
    /**
     Load show metadata from API.
     
     - Parameter imbd: The imbd identification code used to lookup the show.
     
     - Returns: The background art URL, status (continuing, ended) rating and synopsis of the provided show.
     */
    func getShowMeta(imdb: String, completion: (synopsis: String, status: String, coverImageAsString: String, rating: Float) -> Void) {
        Alamofire.request(.GET, "https://api.trakt.tv/shows/\(imdb)", parameters: ["extended": "full,images"], headers: ["trakt-api-key": clientId, "trakt-api-version": "2"]).validate().responseJSON { response in
            guard response.result.isFailure else {
                let responseDict = JSON(response.result.value!)
                let synopsis = responseDict["overview"].string!
                let rating = responseDict["rating"].float!/2
                let status = responseDict["status"].string!.capitalizedString
                var image: String
                if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
                    image = responseDict["images"]["poster"]["medium"].string!
                } else {
                    image = responseDict["images"]["poster"]["full"].string!
                }
                completion(synopsis: synopsis, status: status, coverImageAsString: image, rating: rating)
                return
            }
        }
    }
    /**
     Scrobbles current video.
     
     - Parameter item:      The imdbId of video that is playing.
     - Parameter progress:  The progress of the playing video. Possible values range from 0...1.
     - Parameter type:      The type of the item.
     - Parameter status:    The status of the item.
     */
    func scrobble(id: String, progress: Float, type: TraktTVAPI.type, status: TraktTVAPI.status) {
        guard var credential = OAuthCredential.retrieveCredentialWithIdentifier("trakt") else {
            return
        }
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            if credential.expired {
                do {
                    credential = try OAuthCredential(URLString: "https://api.trakt.tv/oauth/token", refreshToken: credential.refreshToken!, clientID: self.clientId, clientSecret: self.clientSecret, useBasicAuthentication: false)
                } catch {
                    return
                }
            }
            var parameters = [String: AnyObject]()
            
            if type == .Movies {
                parameters = ["movie": ["ids": ["imdb": id]], "progress": progress * 100.0]
            } else {
                parameters = ["episode": ["ids": ["tvdb": Int(id)!]], "progress": progress * 100.0]
            }
            Alamofire.request(.POST, "https://api.trakt.tv/scrobble/\(status.rawValue)", parameters: parameters, encoding: .JSON, headers: ["trakt-api-key": self.clientId, "trakt-api-version": "2", "Authorization": "Bearer \(credential.accessToken)"]).validate().responseJSON(completionHandler: { response in
                if let error = response.result.error {
                    if error.code == -403 {
                        dispatch_async(dispatch_get_main_queue(), {
                            NSNotificationCenter.defaultCenter().postNotificationName(traktAuthenticationErrorNotification, object: nil)
                        })
                    }
                    print("Error is: \(error)")
                }
            })
        }
    }
    /**
     Load episode metadata from API.
     
     - Parameter show:      The TV show.
     - Parameter episode:   The episode.
     
     - Returns: The imageURLString and Imdb identification code of the epsiode.
     */
    func getEpisodeMeta(show: PCTShow, episode: PCTEpisode, completion:(imageURLAsString: String, imdbId: String?) -> Void) {
        Alamofire.request(.GET, "https://api.trakt.tv/shows/\(show.imdbId)/seasons/\(episode.season)/episodes/\(episode.episode)?extended=images", headers: ["trakt-api-key": self.clientId, "trakt-api-version": "2"]).validate().responseJSON { response in
            guard response.result.isFailure else {
                let responseDict = JSON(response.result.value!)
                var image: String!
                if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                    image = responseDict["images"]["screenshot"]["full"].string!
                } else if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
                    image = responseDict["images"]["screenshot"]["medium"].string!
                }
                if let imdbId = responseDict["ids"]["imdb"].string {
                    completion(imageURLAsString: image, imdbId: imdbId)
                } else {
                    completion(imageURLAsString: image, imdbId: nil)
                }
                return
            }
        }
    }
    /**
     Load episode metadata from API.
     
     - Parameter showImdbId:    The Imdb identification code of the show.
     - Parameter episodeNumber: The episode position on the season.
     - Parameter seasonNumber:  The season position in the series.
     
     - Returns: The tvdbid of the episode synchronously.
     */
    private func getEpisodeId(showImdbId: String, episodeNumber: Int, seasonNumber: Int) -> Int {
        let semaphore = dispatch_semaphore_create(0)
        var id: Int!
        Alamofire.request(.GET, "https://api.trakt.tv/shows/\(showImdbId)/seasons/\(seasonNumber)/episodes/\(episodeNumber)", headers: ["trakt-api-key": self.clientId, "trakt-api-version": "2"]).validate().responseJSON { response in
            if response.result.isSuccess {
                id = JSON(response.result.value!)["ids"]["tvdb"].int!
            } else {
                id = 0
            }
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return id
    }
    /**
     Get's users previously watched videos.
     
     - Parameter type: The type of the item (either movie or show).
     
     - Returns: The imdbId of the video.
     */
    func getWatched(type: TraktTVAPI.type, completion:(ids: [String]) -> Void) {
        guard var credential = OAuthCredential.retrieveCredentialWithIdentifier("trakt") else {
            return
        }
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            if credential.expired {
                do {
                    credential = try OAuthCredential(URLString: "https://api.trakt.tv/oauth/token", refreshToken: credential.refreshToken!, clientID: self.clientId, clientSecret: self.clientSecret, useBasicAuthentication: false)
                } catch {
                    return
                }
            }
            let queue = dispatch_queue_create("com.popcorn-time.response.queue", DISPATCH_QUEUE_CONCURRENT)
            Alamofire.request(.GET, "https://api.trakt.tv/sync/watched/\(type.rawValue)", headers: ["trakt-api-key": self.clientId, "trakt-api-version": "2", "Authorization": "Bearer \(credential.accessToken)"]).validate().responseJSON(queue: queue, options: .AllowFragments, completionHandler: { response in
                guard response.result.isFailure else {
                    let responseDict = JSON(response.result.value!)
                    var ids = [String]()
                    for (_, item) in responseDict {
                        if type == .Movies {
                            ids.append(item["movie"]["ids"]["imdb"].string!)
                        } else {
                            var tvdbIds = [String]()
                            let showImdbId = item["show"]["ids"]["imdb"].string!
                            for (_, season) in item["seasons"] {
                                let seasonNumber = season["number"].int!
                                for (_, episode) in season["episodes"] {
                                    let episodeNumber = episode["number"].int!
                                    tvdbIds.append(String(self.getEpisodeId(showImdbId, episodeNumber: episodeNumber, seasonNumber: seasonNumber)))
                                }
                            }
                            ids += tvdbIds
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                       completion(ids: ids)
                    })
                    return
                }
                if response.result.error!.code == -403 {
                    dispatch_async(dispatch_get_main_queue(), {
                        NSNotificationCenter.defaultCenter().postNotificationName(traktAuthenticationErrorNotification, object: nil)
                    })
                }
            })
        }
    }
    /**
     Get's users playback progress of video if applicable.
     
     - Parameter type: The type of the item (either movie or episode).
     
     - Returns: The imdbId of the video and the progress of the video.
     */
    func getPlaybackProgress(type: TraktTVAPI.type, completion: (progressDict: [String: Float]) -> Void) {
        guard var credential = OAuthCredential.retrieveCredentialWithIdentifier("trakt") else {
            return
        }
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            if credential.expired {
                do {
                    credential = try OAuthCredential(URLString: "https://api.trakt.tv/oauth/token", refreshToken: credential.refreshToken!, clientID: self.clientId, clientSecret: self.clientSecret, useBasicAuthentication: false)
                } catch {
                    return
                }
            }
            Alamofire.request(.GET, "https://api.trakt.tv/sync/playback/\(type.rawValue)", headers: ["trakt-api-key": self.clientId, "trakt-api-version": "2", "Authorization": "Bearer \(credential.accessToken)"]).validate().responseJSON { response in
                guard response.result.isFailure else {
                    let responseDict = JSON(response.result.value!)
                    var progressDict = [String: Float]()
                    for (_, item) in responseDict {
                        let imdbId: String
                        if type == .Movies {
                            imdbId = item["movie"]["ids"]["imdb"].string!
                        } else {
                            imdbId = String(item["episode"]["ids"]["tvdb"].int!)
                        }
                        progressDict[imdbId] = item["progress"].float!/100.0
                    }
                    completion(progressDict: progressDict)
                    return
                }
                if response.result.error!.code == -403 {
                    dispatch_async(dispatch_get_main_queue(), {
                        NSNotificationCenter.defaultCenter().postNotificationName(traktAuthenticationErrorNotification, object: nil)
                    })
                }
            }
        }
    }
    /**
     Removes movie, episode or tv show from users watch history.
     
     - Parameter type:  The type of the item (movie, episode or show).
     - Parameter id:    The imdbId or tvdbId of the movie, episode or show.
     */
    func removeItemFromHistory(type: TraktTVAPI.type, id: String) {
        guard var credential = OAuthCredential.retrieveCredentialWithIdentifier("trakt") else {
            return
        }
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            if credential.expired {
                do {
                    credential = try OAuthCredential(URLString: "https://api.trakt.tv/oauth/token", refreshToken: credential.refreshToken!, clientID: self.clientId, clientSecret: self.clientSecret, useBasicAuthentication: false)
                } catch {
                    return
                }
            }
            var parameters = [String: AnyObject]()
            if type == .Movies {
                parameters = ["movies": [["ids": ["imdb": id]]]]
            } else if type == .Episodes {
                parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
            }
            Alamofire.request(.POST, "https://api.trakt.tv/sync/history/remove", parameters: parameters, encoding: .JSON, headers: ["trakt-api-key": self.clientId, "trakt-api-version": "2", "Authorization": "Bearer \(credential.accessToken)"]).validate().responseJSON(completionHandler: { response in
                if let error = response.result.error {
                    if error.code == -403 {
                        dispatch_async(dispatch_get_main_queue(), {
                            NSNotificationCenter.defaultCenter().postNotificationName(traktAuthenticationErrorNotification, object: nil)
                        })
                    }
                    print("Error is: \(error)")
                }
            })
        }
    }
    
}