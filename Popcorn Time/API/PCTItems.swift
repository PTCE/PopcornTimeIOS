

import Foundation

struct PCTMovie {
    let title: String
    let year: Int
    var coverImageAsString: String
    let imdbId: String
    let rating: Float
    let torrents: [PCTTorrent]
    var currentTorrent: PCTTorrent!
    let genres: [String]
    let summary: String
    let runtime: Int
    let trailorURLString: String
    var subtitles: [PCTSubtitle]?
    var currentSubtitle: PCTSubtitle?
    
    init(
        title: String,
        year: Int,
        coverImageAsString: String,
        imdbId: String,
        rating: Float,
        torrents: [PCTTorrent],
        currentTorrent: PCTTorrent? = nil,
        genres: [String],
        summary: String,
        runtime: Int,
        trailorURLString: String,
        subtitles: [PCTSubtitle]? = nil,
        currentSubtitle: PCTSubtitle? = nil) {
        self.title = title
        self.year = year
        self.coverImageAsString = coverImageAsString
        self.imdbId = imdbId
        self.rating = rating
        self.torrents = torrents
        self.currentTorrent = currentTorrent
        self.genres = genres
        self.summary = summary
        self.runtime = runtime
        self.trailorURLString = trailorURLString
        self.subtitles = subtitles
        self.currentSubtitle = currentSubtitle
    }
    
    var description: String {
        get {
            return "<\(self.dynamicType)> title: \"\(self.title)\"\n year: \"\(self.year)\"\n coverImageAsString:  \"\(self.coverImageAsString)\"\n imdbId: \"\(self.imdbId)\"\n rating:  \"\(self.rating)\"\n torrents: \"\(self.torrents)\"\n genres: \"\(self.genres)\"\n summary: \"\(self.summary)\"\n runtime: \"\(self.runtime)\"\n trailorURLString: \"\(self.trailorURLString)\"\n"
        }
    }
}

struct PCTShow {
    var imdbId: String
    var title: String
    var year: String
    var coverImageAsString: String
    var rating: Float
    var genres: [String]?
    var status: String?
    var synopsis: String?
    var animeId: Int?
    
    init(
        imdbId: String,
        title: String,
        year: String,
        coverImageAsString: String,
        rating: Float,
        genres: [String]? = nil,
        status: String? = nil,
        synopsis: String? = nil,
        animeId: Int? = nil
        ) {
        self.imdbId = imdbId
        self.title = title
        self.year = year
        self.coverImageAsString = coverImageAsString
        self.rating = rating
        self.genres = genres
        self.status = status
        self.synopsis = synopsis
        self.animeId = animeId
    }
    
    var description: String {
        get {
            return "<\(self.dynamicType)> title: \"\(self.title)\"\n year: \"\(self.year)\"\n coverImageAsString:  \"\(self.coverImageAsString)\"\n imdbId: \"\(self.imdbId)\"\n rating:  \"\(self.rating)\"\n genres: \"\(self.genres)\"\n status: \"\(self.status)\"\n synopsis: \"\(self.synopsis)\"\n"
        }
    }
}

struct PCTEpisode {
    let season: Int
    let episode: Int
    let title: String
    let overview: String
    let airedDate: NSDate
    let tvdbId: String
    let torrents: [PCTTorrent]
    var currentTorrent: PCTTorrent!
    var coverImageAsString: String?
    var show: PCTShow?
    var subtitles: [PCTSubtitle]?
    var currentSubtitle: PCTSubtitle?
    
    init(
        season: Int,
        episode: Int,
        title: String,
        overview: String,
        airedDate: NSDate,
        tvdbId: String,
        torrents: [PCTTorrent],
        currentTorrent: PCTTorrent? = nil,
        coverImageAsString: String? = nil,
        show: PCTShow? = nil,
        subtitles: [PCTSubtitle]? = nil,
        currentSubtitle: PCTSubtitle? = nil
        ) {
        self.season = season
        self.episode = episode
        self.title = title
        self.overview = overview
        self.airedDate = airedDate
        self.tvdbId = tvdbId
        self.torrents = torrents
        self.currentTorrent = currentTorrent
        self.coverImageAsString = coverImageAsString
        self.show = show
        self.subtitles = subtitles
        self.currentSubtitle = currentSubtitle
    }
    
    var description: String {
        get {
            return "<\(self.dynamicType)> title: \"\(self.title)\"\n season: \"\(self.season)\"\n episode:  \"\(self.episode)\"\n overview: \"\(self.overview)\"\n airedDate: \"\(self.airedDate)\"\n"
        }
    }
}



struct PCTSubtitle {
    let language: String
    let link: String
    let ISO639: String
    
    init(
        language: String,
        link: String,
        ISO639: String
        ) {
        self.language = language
        self.link = link
        self.ISO639 = ISO639
    }
    
     static func dictValue(subtitles: [PCTSubtitle]) -> [String: String] {
        var dict = [String: String]()
        for subtitle in subtitles {
            dict[subtitle.link] = subtitle.language
        }
        return dict
    }
    
    var description: String {
        get {
            return "<\(self.dynamicType)> language: \"\(self.language)\"\n link: \"\(self.link)\"\n"
        }
    }
}

struct PCTCastMetaData {
    let title: String
    let imageUrl: NSURL
    let contentType: String
    let duration: NSTimeInterval
    let subtitle: PCTSubtitle?
    let startPosition: NSTimeInterval
    let url: String
    let mediaAssetsPath: NSURL
    
    init(
        title: String,
        imageUrl: NSURL,
        contentType: String,
        duration: NSTimeInterval,
        subtitle: PCTSubtitle?,
        startPosition: NSTimeInterval,
        url: String,
        mediaAssetsPath: NSURL
        ) {
        self.title = title
        self.imageUrl = imageUrl
        self.contentType = contentType
        self.duration = duration
        self.subtitle = subtitle
        self.startPosition = startPosition
        self.url = url
        self.mediaAssetsPath = mediaAssetsPath
    }
    
    init(
        movie: PCTMovie,
        subtitle: PCTSubtitle?,
        duration: NSTimeInterval,
        startPosition: NSTimeInterval,
        url: String,
        mediaAssetsPath: NSURL
        ) {
        self.init(title: movie.title, imageUrl: NSURL(string: movie.coverImageAsString)!, contentType: "video/mp4", duration: duration, subtitle: subtitle, startPosition: startPosition, url: url, mediaAssetsPath: mediaAssetsPath)
    }
    
    init(
        episode: PCTEpisode,
        subtitle: PCTSubtitle?,
        duration: NSTimeInterval,
        startPosition: NSTimeInterval,
        url: String,
        mediaAssetsPath: NSURL
        ) {
        self.init(title: episode.title, imageUrl: NSURL(string: episode.show!.coverImageAsString)!, contentType: "video/x-matroska", duration: duration, subtitle: subtitle, startPosition: startPosition, url: url, mediaAssetsPath: mediaAssetsPath)
    }
}
