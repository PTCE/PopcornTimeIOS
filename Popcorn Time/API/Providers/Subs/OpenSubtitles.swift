

import Foundation
import AlamofireXMLRPC
import Alamofire

class OpenSubtitles {
    /**
     Creates new instance of OpenSubtitles class.
     
     - Returns: Fully initialised OpenSubtitles class.
     */
    static let sharedInstance = OpenSubtitles()
    
    /// Private Variables.
    private let baseURL = "http://api.opensubtitles.org:80/xml-rpc"
    private let secureBaseURL = "https://api.opensubtitles.org:443/xml-rpc"
    private let userAgent = "Popcorn Time v1"
    private var token: String?
    var protectionSpace: NSURLProtectionSpace {
        let url = NSURL(string: secureBaseURL)!
        return NSURLProtectionSpace(host: url.host!, port: url.port!.integerValue, protocol: url.scheme, realm: nil, authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
    }
    /**
     Load subtitles from API. Use episode or ImdbId not both. Using ImdbId rewards better results.
     
     - Parameter episode:   The TV show episode.
     - Parameter imdbId:    The Imdb identification code of the episode or movie.
     - Parameter limit:     The limit of subtitles to fetch as a `String`. Defaults to 300.
     
     - Returns: Array of `PCTSubtitles`.
     */
    func search(episode: PCTEpisode? = nil, imdbId: String? = nil, limit: String = "300", completion:(subtitles: [PCTSubtitle])-> Void) {
        var params: XMLRPCStructure = ["sublanguageid": "all"]
        if let imdbId = imdbId {
           params["imdbid"] = imdbId.stringByReplacingOccurrencesOfString("tt", withString: "")
        } else if let episode = episode {
            params["query"] = episode.title
            params["season"] = String(episode.season)
            params["episode"] = String(episode.episode)
        }
        let array: XMLRPCArray = [params]
        let limit: XMLRPCStructure = ["limit": limit]
        let queue = dispatch_queue_create("com.popcorn-time.response.queue", DISPATCH_QUEUE_CONCURRENT)
        AlamofireXMLRPC.request(secureBaseURL, methodName: "SearchSubtitles", parameters: [token!, array, limit], headers: ["User-Agent": userAgent]).response(queue: queue, responseSerializer: Request.XMLRPCResponseSerializer(), completionHandler: { response in
            guard response.result.isSuccess else {
                print("Error is \(response.result.error!)")
                return
            }
            var subtitles = [PCTSubtitle]()
            for info in response.result.value![0]["data"].array! {
                if !subtitles.contains({ subtitle in subtitle.language == info["LanguageName"].string!}){
                    subtitles.append(PCTSubtitle(language: info["LanguageName"].string!, link: info["SubDownloadLink"].string!, ISO639: info["ISO639"].string!))
                }
            }
            subtitles.sortInPlace({ $0.language < $1.language })
            dispatch_async(dispatch_get_main_queue(), { 
                completion(subtitles: subtitles)
            })
        })
    }
    /**
     Login to OpenSubtitles API. Login is required to use the API.
     */
    func login(completion:() -> Void, error:((error: NSError) -> Void)? = nil) {
        var username = ""
        var password = ""
        if let credential = NSURLCredentialStorage.sharedCredentialStorage().credentialsForProtectionSpace(protectionSpace)?.values.first {
            username = credential.user!
            password = credential.password!
        }
        AlamofireXMLRPC.request(secureBaseURL, methodName: "LogIn", parameters: [username, password, "en", userAgent]).validate().responseXMLRPC { response in
            guard response.result.isSuccess && Int(response.result.value![0]["status"].string!.componentsSeparatedByString(" ").first!)! == 200 else {
                var statusError = response.result.error
                if statusError == nil {
                    statusError = NSError(domain: "com.AlamofireXMLRPC.error", code: Int(response.result.value![0]["status"].string!.componentsSeparatedByString(" ").first!)!, userInfo: [NSLocalizedDescriptionKey: "Username or password is incorrect."])
                }
                print("Error is \(statusError!)")
                error?(error: statusError!)
                return
            }
            self.token = response.result.value![0]["token"].string
            completion()
        }
    }

}
