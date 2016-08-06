

import Foundation
import SwiftyJSON
import Alamofire

class TVAPI {
    private let TVShowsAPIEndpoint = "https://api-fetch.website/tv/"
    /**
     Creates new instance of TVAPI class.
     
     - Returns: Fully initialised TVAPI class.
     */
    static let sharedInstance = TVAPI()
    /**
     Possible genres used in API call.
     */
    enum genres: String {
        case All = "All"
        case Action = "Action"
        case Adventure = "Adventure"
        case Animation = "Animation"
        case Children = "Children"
        case Comedy = "Comedy"
        case Crime = "Crime"
        case Documentary = "Documentary"
        case Drama = "Drama"
        case Family = "Family"
        case Fantasy = "Fantasy"
        case GameShow = "Game Show"
        case HomeAndGarden = "Home and Garden"
        case Horror = "Horror"
        case MiniSeries = "Mini Series"
        case Mystery = "Mystery"
        case News = "News"
        case Reality = "Reality"
        case Romance = "Romance"
        case SciFi = "Science Fiction"
        case Soap = "Soap"
        case SpecialInterest = "Special Interest"
        case Sport = "Sport"
        case Suspense = "Suspense"
        case TalkShow = "Talk Show"
        case Thriller = "Thriller"
        case Western = "Western"
        
        static let arrayValue = [All, Action, Adventure, Animation, Children, Comedy, Crime, Documentary, Drama, Family, Fantasy, GameShow, HomeAndGarden, Horror, MiniSeries, Mystery, News, Reality, Romance, SciFi, Soap, SpecialInterest, Sport, Suspense, TalkShow, Thriller, Western]
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
        case Trending = "trending"
        
        static let arrayValue = [Trending, Popularity, Rating, Date, Year, Alphabet]
        
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
            case .Trending:
                return "Trending"
            }
        }
    }
    /**
     Load TV Shows from API.
     
     - Parameter page:       The page number to load.
     - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
     - Paramter genre:       Only return TV Shows that match the provided genre.
     - Parameter searchTerm: Only return movies that match the provided string.
     
     - Returns: Array of `PCTShows`.
     */
    func load(
        page: Int,
        filterBy: filters,
        genre: genres = .All,
        searchTerm: String? = nil,
        completion: (items: [PCTShow]) -> Void) {
        var params = ["sort": filterBy.rawValue, "genre": genre.rawValue.stringByReplacingOccurrencesOfString(" ", withString: "-")]
        if searchTerm != nil {
            params["keywords"] = searchTerm!
        }
        Alamofire.request(.GET, TVShowsAPIEndpoint + "shows/\(page)", parameters: params).validate().responseJSON { response in
            guard response.result.isSuccess else {
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotification, object: response.result.error!)
                print("Error is: \(response.result.error!)")
                return
            }
            let shows =  JSON(response.result.value!)
            var pctItems = [PCTShow]()
            for (_, show) in shows {
                let id = show["imdb_id"].string!
                let title = show["title"].string!
                let year = show["year"].string
                let coverImage = show["images"]["poster"].string!.stringByReplacingOccurrencesOfString("original", withString: "thumb")
                let rating = show["rating"]["percentage"].float!/20.0
                let pctItem = PCTShow(imdbId: id, title: title, year: year ?? "", coverImageAsString: coverImage, rating: rating)
                pctItems.append(pctItem)
            }
            completion(items: pctItems)
        }
    }
    
    /**
     Get detailed TV Show information.
     
     - Parameter imbdId: The imbd identification code.
     
     - Returns: Array of `PCTEpisodes`, the genres of the show, the status of the show (Continuing, Ended etc.), a small description of show, the length of the show, the number of seasons in the show.
     */
    func getShowInfo(imdbId: String, completion: (genres: [String], status: String, synopsis: String, episodes: [PCTEpisode], seasonNumbers: [Int]) -> Void) {
        Alamofire.request(.GET, TVShowsAPIEndpoint + "show/\(imdbId)").validate().responseJSON { response in
            guard response.result.isSuccess else {
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotification, object: response.result.error!)
                print("Error is: \(response.result.error!)")
                return
            }
            let show =  JSON(response.result.value!)
            let genres = show["genres"].arrayObject! as! [String]
            let status = show["status"].string!
            let synopsis = show["synopsis"].string!
            var pctEpisodes = [PCTEpisode]()
            var seasons = [Int]()
            for (_, episodes) in show["episodes"] {
                let season = episodes["season"].int!
                if !seasons.contains(season) {
                    seasons.append(season)
                }
                let episode = episodes["episode"].int!
                let title = episodes["title"].string!
                let overview = episodes["overview"].string!
                let tvdbId = String(episodes["tvdb_id"].int!)
                let airedDate = NSDate(timeIntervalSince1970: Double(episodes["first_aired"].int!))
                var torrents = [PCTTorrent]()
                for (index, torrent) in episodes["torrents"] {
                    if index != "0" {
                        let torrent = PCTTorrent(url: torrent["url"].string ?? "", seeds: torrent["seeds"].int!, peers: torrent["peers"].int!, quality: index)
                        torrents.append(torrent)
                    }
                }
                torrents.sortInPlace({$0.quality > $1.quality})
                let pctEpisode = PCTEpisode(season: season, episode: episode, title: title, overview: overview, airedDate: airedDate, tvdbId: tvdbId, torrents: torrents)
                pctEpisodes.append(pctEpisode)
            }
            seasons.sortInPlace(<)
            pctEpisodes.sortInPlace({ $0.episode < $1.episode })
            completion(genres: genres, status: status, synopsis: synopsis, episodes: pctEpisodes, seasonNumbers: seasons)
        }
    }
    /**
     Get detailed episode information.
     
     - Parameter episode: The episode you want more information about.
     
     - Returns: ImageURL and subtitles. Completion block called twice. First time when imageURL has been recieved and second when subtitles have been recieved.
     */
    func getEpisodeInfo(episode: PCTEpisode, completion: (imageURLAsString: String, subtitles: [PCTSubtitle]?) -> Void) {
        TraktTVAPI.sharedInstance.getEpisodeMeta(episode.show!, episode: episode, completion: { (imageURLAsString, imdbId) in
            completion(imageURLAsString: imageURLAsString, subtitles: nil)
            OpenSubtitles.sharedInstance.login({
                OpenSubtitles.sharedInstance.search(episode, imdbId: imdbId, completion: {
                    subtitles in
                    completion(imageURLAsString: imageURLAsString, subtitles: subtitles)
                })
            })
        })
    }
}