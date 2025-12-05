import Foundation

struct ImpactModel: Codable {
    let sleepPerHourGain: Double
    let stepsPer1000Gain: Double
    let alcoholPerUnitLoss: Double
    let smokingPerLevelLoss: Double
    let exercisePerDayGain: Double
    
    // Default values if not provided
    static let `default` = ImpactModel(
        sleepPerHourGain: 0.5,
        stepsPer1000Gain: 0.1,
        alcoholPerUnitLoss: 0.2,
        smokingPerLevelLoss: 0.8,
        exercisePerDayGain: 0.3
    )
}

