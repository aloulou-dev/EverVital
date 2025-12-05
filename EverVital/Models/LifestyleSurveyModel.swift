import Foundation

struct LifestyleSurveyModel {
    let sleepHours: Double
    let dailySteps: Int
    let alcoholPerWeek: Double
    let smokingIntensity: Double // 0-10 scale
    let exerciseDays: Int // 0-7
    
    init(sleepHours: Double = 7.0,
         dailySteps: Int = 5000,
         alcoholPerWeek: Double = 0,
         smokingIntensity: Double = 0,
         exerciseDays: Int = 0) {
        self.sleepHours = sleepHours
        self.dailySteps = dailySteps
        self.alcoholPerWeek = alcoholPerWeek
        self.smokingIntensity = smokingIntensity
        self.exerciseDays = exerciseDays
    }
    
    // Helper to create from UserHealthData and HealthKit data
    static func from(userData: UserHealthData, healthKitSteps: Int? = nil, healthKitSleep: Double? = nil) -> LifestyleSurveyModel {
        // Only use HealthKit sleep if > 0 and valid, otherwise use manual entry or default
        let sleep: Double
        if let hkSleep = healthKitSleep, hkSleep > 0 {
            sleep = hkSleep
        } else {
            sleep = userData.sleepHours ?? 7.0
        }
        let steps = healthKitSteps ?? userData.appleSteps ?? 5000
        
        // Convert smoking preset to intensity (0-10)
        var smokingIntensity: Double = 0
        if let smoking = userData.smoking {
            switch smoking.preset.lowercased() {
            case "current":
                if let frequency = smoking.followUpData?["frequency"] {
                    switch frequency.lowercased() {
                    case "occasional": smokingIntensity = 3
                    case "daily": smokingIntensity = 7
                    case "heavy": smokingIntensity = 10
                    default: smokingIntensity = 5
                    }
                } else {
                    smokingIntensity = 5
                }
            case "former":
                smokingIntensity = 1 // Minimal residual impact
            case "never":
                smokingIntensity = 0
            default:
                smokingIntensity = 0
            }
        }
        
        // Convert alcohol preset to units per week
        var alcoholPerWeek: Double = 0
        if let alcohol = userData.alcohol {
            switch alcohol.preset.lowercased() {
            case "never", "none":
                alcoholPerWeek = 0
            case "rarely", "occasional":
                alcoholPerWeek = 2
            case "moderate", "weekly":
                alcoholPerWeek = 7
            case "regular", "daily":
                alcoholPerWeek = 14
            case "heavy", "excessive":
                alcoholPerWeek = 25
            default:
                alcoholPerWeek = 3
            }
        }
        
        // Convert exercise preset to days per week
        var exerciseDays: Int = 0
        if let exercise = userData.exercise {
            switch exercise.preset.lowercased() {
            case "very_active", "daily":
                exerciseDays = 7
            case "active", "regular":
                exerciseDays = 5
            case "moderate", "weekly":
                exerciseDays = 3
            case "light", "occasional":
                exerciseDays = 1
            case "sedentary", "none":
                exerciseDays = 0
            default:
                exerciseDays = 2
            }
        }
        
        return LifestyleSurveyModel(
            sleepHours: sleep,
            dailySteps: steps,
            alcoholPerWeek: alcoholPerWeek,
            smokingIntensity: smokingIntensity,
            exerciseDays: exerciseDays
        )
    }
}

