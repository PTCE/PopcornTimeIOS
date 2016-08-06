

import Foundation
import UIKit

enum Health {
    case Bad
    case Medium
    case Good
    case Excellent
    case Unknown
    
    func color() -> UIColor {
        switch self {
        case .Bad:
            return UIColor(red: 212.0/255.0, green: 14.0/255.0, blue: 0.0, alpha: 1.0)
        case .Medium:
            return UIColor(red: 212.0/255.0, green: 120.0/255.0, blue: 0.0, alpha: 1.0)
        case .Good:
            return UIColor(red: 201.0/255.0, green: 212.0/255.0, blue: 0.0, alpha: 1.0)
        case .Excellent:
            return UIColor(red: 90.0/255.0, green: 186.0/255.0, blue: 0.0, alpha: 1.0)
        case .Unknown:
            return UIColor(red: 105.0/255.0, green: 105.0/255.0, blue: 105.0, alpha: 1.0)
        }
    }
}

struct PCTTorrent {
    let seeds, peers: Int
    let url: String
    var health: Health = .Unknown
    var quality, size, hash: String?
    
    init(
        url: String,
        seeds: Int,
        peers: Int,
        quality: String? = nil,
        size: String? = nil,
        hash: String? = nil) {
        self.url = url
        self.seeds = seeds
        self.peers = peers
        
        self.quality = quality
        self.size = size
        self.hash = hash
        
        calcHealth()
    }
    
    mutating func calcHealth() {
        let seeds = self.seeds
        let peers = self.peers
        
        // First calculate the seed/peer ratio
        let ratio = peers > 0 ? (seeds / peers) : seeds
        
        // Normalize the data. Convert each to a percentage
        // Ratio: Anything above a ratio of 5 is good
        let normalizedRatio = min(ratio / 5 * 100, 100)
        // Seeds: Anything above 30 seeds is good
        let normalizedSeeds = min(seeds / 30 * 100, 100)
        
        // Weight the above metrics differently
        // Ratio is weighted 60% whilst seeders is 40%
        let weightedRatio = Double(normalizedRatio) * 0.6
        let weightedSeeds = Double(normalizedSeeds) * 0.4
        let weightedTotal = weightedRatio + weightedSeeds
        
        // Scale from [0, 100] to [0, 3]. Drops the decimal places
        var scaledTotal = ((weightedTotal * 3.0) / 100.0)// | 0.0
        if (scaledTotal < 0) {
            scaledTotal = 0
        }
        
        switch floor(scaledTotal) {
        case 0:
            self.health = .Bad
        case 1:
            self.health = .Medium
        case 2:
            self.health = .Good
        case 3:
            self.health = .Excellent
        default:
            self.health = .Unknown
        }
    }
}
