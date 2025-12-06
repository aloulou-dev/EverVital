import Foundation

struct HealthScore: Codable {
    let score: Int
    let lastUpdated: Date
    
    init(score: Int, lastUpdated: Date = Date()) {
        self.score = score
        self.lastUpdated = lastUpdated
    }
}


