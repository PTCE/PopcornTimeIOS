

import Foundation
import Alamofire
import SwiftyJSON

class AnimeAPI {
    private let animeAPIEndpoint = "http://ptp.haruhichan.com/"
    /**
     Creates new instance of AnimeAPI class
     
     - Returns: Fully initialised AnimeAPI class
     */
    static let sharedInstance = AnimeAPI()
    /**
     Possible genres used in API call.
     */
    enum genres: String {
        case All = "All"
        case Action = "Action"
        case Adventure = "Adventure"
        case Cars = "Cars"
        case Comedy = "Comedy"
        case Dementia = "Dementia"
        case Demons = "Demons"
        case Drama = "Drama"
        case Ecchi = "Ecchi"
        case Fantasy = "Fantasy"
        case Game = "Game"
        case Harem = "Harem"
        case Historical = "Historical"
        case Horror = "Horror"
        case Josei = "Josei"
        case Kids = "Kids"
        case Magic = "Magic"
        case MartialArts = "Martial Arts"
        case Mecha = "Mecha"
        case Military = "Military"
        case Music = "Music"
        case Mystery = "Mystery"
        case Parody = "Parody"
        case Police = "Police"
        case Psychological = "Psychological"
        case Romance = "Romance"
        case Samurai = "Samurai"
        case School = "School"
        case SciFi = "Sci-Fi"
        case Seinen = "Seinen"
        case Shoujo = "Shoujo"
        case ShoujoAi = "Shoujo Ai"
        case Shounen = "Shounen"
        case ShounenAi = "Shounen Ai"
        case SliceOfLife = "Slice of Life"
        case Space = "Space"
        case Sports = "Sports"
        case SuperPower = "Super Power"
        case Supernatural = "Supernatural"
        case Thriller = "Thriller"
        case Vampire = "Vampire"
        
        static let arrayValue = [All, Action, Adventure, Cars, Comedy, Dementia, Demons, Drama, Ecchi, Fantasy, Game, Harem, Historical, Horror, Josei, Mystery, Kids, Magic, MartialArts, Mecha, Military, Music, Mystery, Parody, Police, Psychological, Romance, Samurai, School, SciFi, Seinen, Shoujo, ShoujoAi, Shounen, ShounenAi, SliceOfLife, Space, Sports, SuperPower, Supernatural, Thriller, Vampire]
    }
    /**
     Possible filters used in API call.
     */
    enum filters: String {
        case Popularity = "popularity"
        case Year = "year"
        case Date = "updated"
        case Rating = "rating"
        case Alphabet = "name"
        
        static let arrayValue = [Popularity, Rating, Date, Year, Alphabet]
        
        func stringValue() -> String {
            switch self {
            case .Popularity:
                return "Popular"
            case .Year:
                return "Year"
            case .Date:
                return "Last Updated"
            case .Rating:
                return "Top Rated"
            case .Alphabet:
                return "A-Z"
            }
        }
    }
    /**
     Load Anime from API.
     
     - Parameter page:       The page number to load.
     - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
     - Paramter genre:       Only return anime that match the provided genre.
     - Parameter searchTerm: Only return movies that match the provided string.
     
     - Returns: Array of `PCTAnimes`.
     */
    func load(
        page: Int,
        filterBy: filters,
        genre: genres = .All,
        searchTerm: String? = nil,
        completion: (items: [PCTShow]) -> Void) {
        var params: [String: AnyObject] = ["sort": filterBy.rawValue, "limit": 30, "type": genre.rawValue.stringByReplacingOccurrencesOfString(" ", withString: "-"), "order": "asc", "page": page - 1]
        if searchTerm != nil {
            params["search"] = searchTerm!
        }
        let queue = dispatch_queue_create("com.popcorn-time.response.queue", DISPATCH_QUEUE_CONCURRENT)
        Alamofire.request(.GET, animeAPIEndpoint + "/list.php", parameters: params).validate().responseJSON(queue: queue, options: .AllowFragments, completionHandler: { response in
            guard response.result.isSuccess else {
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotification, object: response.result.error!)
                print("Error is: \(response.result.error!)")
                return
            }
            let animes = JSON(response.result.value!)
            var pctAnimes = [PCTShow]()
            for (_, anime) in animes {
                let id = anime["id"].int!
                let name = anime["name"].string!.stringByReplacingOccurrencesOfString("(TV)", withString: "")
                let image = anime["malimg"].string!
                var show: PCTShow? = PCTShow(imdbId: "", title: name, year: "", coverImageAsString: image, rating: 0.0, animeId: id)
                self.loadMeta(&show)
                if let show = show {
                    pctAnimes.append(show)
                }
            }
            dispatch_async(dispatch_get_main_queue(), {
                completion(items: pctAnimes)
            })
        })
    }
    /**
     Load Anime metadata.
     
     - Parameter show: The current show you want metadata added to
     
     - Returns: The same `PCTShow` object but with an ImdbId, genres and release year. Returns nil if show doesnt exist on imdb or operation failed.
     */
    func loadMeta(inout show: PCTShow?) {
        let semaphore = dispatch_semaphore_create(0)
        Alamofire.request(.GET, "http://www.omdbapi.com/?t=\(show!.title.stringByReplacingOccurrencesOfString(" ", withString: "+"))").validate().responseJSON  { response in
            if response.result.isSuccess {
                let responseDict = JSON(response.result.value!)
                if responseDict["Response"].string! == "True" {
                    show!.imdbId = responseDict["imdbID"].string!
                    show!.genres = responseDict["Genre"].string!.stringByReplacingOccurrencesOfString(" ", withString: "").componentsSeparatedByString(",")
                    show!.year = responseDict["Year"].string!.componentsSeparatedByString("–").first!
                } else {
                    show = nil
                }
            } else {
                show = nil
            }
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    /**
     Get detailed Anime information.
     
     - Parameter id: The identification code.
     
     - Returns: Array of `PCTEpisodes`, the status of the show (continuing, ended etc.), a small description of show and the number of seasons in the show.
     */
    func getAnimeInfo(id: Int, imdbId: String, completion: (synopsis: String, status: String, imageURL: String, episodes: [PCTEpisode], seasonNumbers: [Int], rating: Float) -> Void) {
        Alamofire.request(.GET, animeAPIEndpoint + "/anime.php?id=\(id)").validate().responseJSON { response in
            guard response.result.isSuccess else {
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotification, object: response.result.error!)
                print("Error is: \(response.result.error!)")
                return
            }
            let responseDict = JSON(response.result.value!)
            var torrents = [PCTTorrent]()
            for (_, episode) in responseDict["episodes"] {
                torrents.append(PCTTorrent(url: episode["magnet"].string!, seeds: 0, peers: 0, quality: episode["quality"].string!.componentsSeparatedByString("-").first!))
            }
            TraktTVAPI.sharedInstance.getShowMeta(imdbId, completion: { synopsis, status, coverImageAsString, rating in
                completion(synopsis: synopsis, status: status, imageURL: coverImageAsString, episodes: [], seasonNumbers: [], rating: rating)
            })
        }
    }
    
}