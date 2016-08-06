

import Foundation
import SwiftyJSON
import Alamofire

class MovieAPI {
    private let moviesAPIEndpoint = "https://movies.api-fetch.website/movies/api/v2/"
    /**
     Creates new instance of MovieAPI class.
     
     - Returns: Fully initialised MovieAPI class.
     */
    static let sharedInstance = MovieAPI()
    /**
     Possible genres used in API call.
     */
    enum genres: String {
        case All = "All"
        case Action = "Action"
        case Adventure = "Adventure"
        case Animation = "Animation"
        case Biography = "Biography"
        case Comedy = "Comedy"
        case Crime = "Crime"
        case Documentary = "Documentary"
        case Drama = "Drama"
        case Family = "Family"
        case Fantasy = "Fantasy"
        case FilmNoir = "Film-Noir"
        case History = "History"
        case Horror = "Horror"
        case Music = "Music"
        case Musical = "Musical"
        case Mystery = "Mystery"
        case Romance = "Romance"
        case SciFi = "Sci-Fi"
        case Short = "Short"
        case Sport = "Sport"
        case Thriller = "Thriller"
        case War = "War"
        case Western = "Western"
        
        static let arrayValue = [All, Action, Adventure, Animation, Biography, Comedy, Crime, Documentary, Drama, Family, Fantasy, FilmNoir, History, Horror, Music, Musical, Mystery, Romance, SciFi, Short, Sport, Thriller, War, Western]
    }
    /**
     Possible filters used in API call.
     */
    enum filters: String {
        case Trending = "trending_score"
        case Popularity = "seeds"
        case Rating = "rating"
        case Date = "date_added"
        case Year = "year"
        case Alphabet = "title"
        
        static let arrayValue = [Trending, Popularity, Rating, Date, Year, Alphabet]
        
        func stringValue() -> String {
            switch self {
            case .Popularity:
                return "Popular"
            case .Year:
                return "Year"
            case .Date:
                return "Release Date"
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
     Load Movies from API.
     
     - Parameter page:       The page number to load.
     - Parameter limit:      The number of movies to be recieved.
     - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
     - Paramter genre:       Only return movies that match the provided genre.
     - Parameter searchTerm: Only return movies that match the provided string.
     
     - Returns: Array of `PCTMovies`.
     */
    func load(
        page: Int,
        limit: Int = 30,
        filterBy: filters,
        genre: genres = .All,
        searchTerm: String? = nil,
        completion: (items: [PCTMovie]) -> Void) {
        var params: [String: AnyObject] = ["sort_by": filterBy.rawValue, "limit": limit, "page": page, "genre": genre.rawValue, "with_rt_ratings": "true", "lang": "en"]
        if let searchTerm = searchTerm where !searchTerm.isEmpty {
            params["query_term"] = searchTerm
        }
        if filterBy == .Alphabet {
            params["order_by"] = "asc"
        }
        Alamofire.request(.GET, moviesAPIEndpoint + "list_movies_pct.json", parameters: params).validate().responseJSON { response in
            guard response.result.isSuccess else {
                NSNotificationCenter.defaultCenter().postNotificationName(errorNotification, object: response.result.error!)
                print("Error is: \(response.result.error!)")
                return
            }
            let movies =  JSON(response.result.value!)["data"]["movies"]
            var pctMovies = [PCTMovie]()
            for (_, movie) in movies {
                let description = movie["description_full"].string!
                let runtime = movie["runtime"].int!
                let trailorString = movie["yt_trailer_code"].string!
                let rating = movie["rating"].float!/2
                let title = movie["title"].string!
                let year = movie["year"].int!
                let coverImage = movie["large_cover_image"].string!
                let id = movie["imdb_code"].string!
                let genres = movie["genres"].arrayObject! as! [String]
                var torrents = [PCTTorrent]()
                for (_, torrent) in movie["torrents"] {
                    torrents.append(PCTTorrent(url: torrent["url"].string!, seeds: torrent["seeds"].int!, peers: torrent["peers"].int!, quality: torrent["quality"].string!, size: torrent["size"].string!, hash: torrent["hash"].string!))
                }
                let pctMovie = PCTMovie(title: title, year: year, coverImageAsString: coverImage, imdbId: id, rating: rating, torrents: torrents, genres: genres, summary: description, runtime: runtime, trailorURLString: trailorString)
                pctMovies.append(pctMovie)
            }
            completion(items: pctMovies)
        }
    }
}