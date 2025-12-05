import Foundation

struct UserHealthData: Codable {
    // Basic Information
    var age: Int?
    var weight: Double?
    var height: Double?
    var sleepHours: Double?
    
    // Lifestyle - Structured with presets and optional details
    var smoking: LifestyleCategory?
    var alcohol: LifestyleCategory?
    var exercise: LifestyleCategory?
    var diet: LifestyleCategory?
    var stress: LifestyleCategory?
    
    // HealthKit Data
    var appleSteps: Int?
    var appleHeartRate: Double?
    var appleSleepHours: Double?
    
    struct LifestyleCategory: Codable {
        var preset: String
        var optionalDetails: String?
        var followUpData: [String: String]? // For conditional questions like frequency, duration, etc.
        
        init(preset: String, optionalDetails: String? = nil, followUpData: [String: String]? = nil) {
            self.preset = preset
            self.optionalDetails = optionalDetails
            self.followUpData = followUpData
        }
    }
    
    init(age: Int? = nil,
         weight: Double? = nil,
         height: Double? = nil,
         sleepHours: Double? = nil,
         smoking: LifestyleCategory? = nil,
         alcohol: LifestyleCategory? = nil,
         exercise: LifestyleCategory? = nil,
         diet: LifestyleCategory? = nil,
         stress: LifestyleCategory? = nil,
         appleSteps: Int? = nil,
         appleHeartRate: Double? = nil,
         appleSleepHours: Double? = nil) {
        self.age = age
        self.weight = weight
        self.height = height
        self.sleepHours = sleepHours
        self.smoking = smoking
        self.alcohol = alcohol
        self.exercise = exercise
        self.diet = diet
        self.stress = stress
        self.appleSteps = appleSteps
        self.appleHeartRate = appleHeartRate
        self.appleSleepHours = appleSleepHours
    }
}

