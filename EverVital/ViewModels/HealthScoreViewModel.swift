import Foundation
import FirebaseAuth
import FirebaseFirestore
import Observation

@Observable
class HealthScoreViewModel {
    var currentScore: Int?
    var lastUpdated: Date?
    var isLoading = false
    var errorMessage: String?
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // Calculate health score from user data
    func calculateHealthScore(from userData: UserHealthData, healthKitData: [String: Any]?) -> Int {
        var totalScore: Double = 0.0
        var totalWeight: Double = 0.0
        
        // BMI Score (20%)
        if let bmiScore = calculateBMIScore(weight: userData.weight, height: userData.height) {
            totalScore += Double(bmiScore) * 0.20
            totalWeight += 0.20
        }
        
        // Exercise Score (20%)
        if let exerciseScore = calculateExerciseScore(
            exercise: userData.exercise,
            healthKitSteps: healthKitData?["appleSteps"] as? Int ?? userData.appleSteps
        ) {
            totalScore += Double(exerciseScore) * 0.20
            totalWeight += 0.20
        }
        
        // Smoking Score (20%)
        if let smokingScore = calculateSmokingScore(smoking: userData.smoking) {
            totalScore += Double(smokingScore) * 0.20
            totalWeight += 0.20
        }
        
        // Diet Score (10%)
        if let dietScore = calculateDietScore(diet: userData.diet) {
            totalScore += Double(dietScore) * 0.10
            totalWeight += 0.10
        }
        
        // Alcohol Score (10%)
        if let alcoholScore = calculateAlcoholScore(alcohol: userData.alcohol) {
            totalScore += Double(alcoholScore) * 0.10
            totalWeight += 0.10
        }
        
        // Sleep Score (10%)
        if let sleepScore = calculateSleepScore(
            surveySleep: userData.sleepHours,
            healthKitSleep: healthKitData?["appleSleepHours"] as? Double ?? userData.appleSleepHours
        ) {
            totalScore += Double(sleepScore) * 0.10
            totalWeight += 0.10
        }
        
        // Stress Score (10%)
        if let stressScore = calculateStressScore(stress: userData.stress) {
            totalScore += Double(stressScore) * 0.10
            totalWeight += 0.10
        }
        
        // Normalize score if some categories are missing
        if totalWeight > 0 {
            let normalizedScore = totalScore / totalWeight
            return min(100, max(0, Int(round(normalizedScore))))
        }
        
        return 0
    }
    
    // BMI Score: 0-100 (optimal BMI is 18.5-24.9)
    private func calculateBMIScore(weight: Double?, height: Double?) -> Int? {
        guard let weight = weight, let height = height, height > 0, weight > 0 else {
            return nil
        }
        
        let heightInMeters = height / 100.0 // Convert cm to meters
        let bmi = weight / (heightInMeters * heightInMeters)
        
        // Optimal BMI range: 18.5-24.9 = 100 points
        // Underweight (<18.5) or Overweight (>24.9) = decreasing score
        if bmi >= 18.5 && bmi <= 24.9 {
            return 100
        } else if bmi < 18.5 {
            // Underweight: 0-100 based on how far from 18.5
            let score = max(0, Int(100 * (bmi / 18.5)))
            return score
        } else {
            // Overweight: 0-100 based on how far from 24.9
            // BMI > 30 is considered obese, score drops faster
            if bmi <= 30 {
                let score = max(0, Int(100 * (1 - ((bmi - 24.9) / 5.1))))
                return score
            } else {
                // BMI > 30: score drops more sharply
                let excess = bmi - 30
                let score = max(0, Int(60 * (1 - min(1, excess / 10))))
                return score
            }
        }
    }
    
    // Exercise Score: 0-100
    private func calculateExerciseScore(exercise: UserHealthData.LifestyleCategory?, healthKitSteps: Int?) -> Int? {
        // Prefer HealthKit steps if available
        if let steps = healthKitSteps, steps > 0 {
            // 10,000 steps = 100 points, scale down from there
            if steps >= 10000 {
                return 100
            } else if steps >= 7500 {
                return 85
            } else if steps >= 5000 {
                return 70
            } else if steps >= 3000 {
                return 50
            } else {
                return min(40, Int((Double(steps) / 3000.0) * 40))
            }
        }
        
        // Fallback to survey exercise preset
        guard let exercise = exercise else { return nil }
        
        switch exercise.preset.lowercased() {
        case "very_active", "daily":
            return 100
        case "active", "regular":
            return 85
        case "moderate", "weekly":
            return 70
        case "light", "occasional":
            return 50
        case "sedentary", "none":
            return 20
        default:
            return 50 // Default middle score
        }
    }
    
    // Smoking Score: 0-100 (never = 100, former = varies, current = 0-30)
    private func calculateSmokingScore(smoking: UserHealthData.LifestyleCategory?) -> Int? {
        guard let smoking = smoking else { return nil }
        
        switch smoking.preset.lowercased() {
        case "never":
            return 100
        case "former":
            // Former smokers: score based on how long ago they quit
            if let yearsQuitStr = smoking.followUpData?["yearsQuit"],
               let yearsQuit = Double(yearsQuitStr) {
                // More years since quitting = higher score
                if yearsQuit >= 10 {
                    return 90
                } else if yearsQuit >= 5 {
                    return 75
                } else if yearsQuit >= 2 {
                    return 60
                } else {
                    return 45
                }
            }
            return 70 // Default for former smokers without follow-up data
        case "current":
            // Current smokers: very low score, varies by frequency
            if let frequency = smoking.followUpData?["frequency"] {
                switch frequency.lowercased() {
                case "occasional":
                    return 30
                case "daily":
                    return 15
                case "heavy":
                    return 5
                default:
                    return 20
                }
            }
            return 20 // Default for current smokers
        default:
            return 50
        }
    }
    
    // Diet Score: 0-100
    private func calculateDietScore(diet: UserHealthData.LifestyleCategory?) -> Int? {
        guard let diet = diet else { return nil }
        
        switch diet.preset.lowercased() {
        case "excellent", "very_healthy":
            return 100
        case "good", "healthy":
            return 85
        case "moderate", "average":
            return 65
        case "poor", "unhealthy":
            return 35
        case "very_poor":
            return 15
        default:
            return 50
        }
    }
    
    // Alcohol Score: 0-100
    private func calculateAlcoholScore(alcohol: UserHealthData.LifestyleCategory?) -> Int? {
        guard let alcohol = alcohol else { return nil }
        
        switch alcohol.preset.lowercased() {
        case "never", "none":
            return 100
        case "rarely", "occasional":
            return 90
        case "moderate", "weekly":
            return 75
        case "regular", "daily":
            return 50
        case "heavy", "excessive":
            return 20
        default:
            return 70
        }
    }
    
    // Sleep Score: 0-100 (optimal: 7-9 hours)
    private func calculateSleepScore(surveySleep: Double?, healthKitSleep: Double?) -> Int? {
        // Prefer HealthKit sleep if available
        let sleepHours = healthKitSleep ?? surveySleep
        guard let sleep = sleepHours, sleep > 0 else { return nil }
        
        // Optimal: 7-9 hours = 100 points
        if sleep >= 7 && sleep <= 9 {
            return 100
        } else if sleep >= 6 && sleep < 7 {
            // 6-7 hours: 80 points
            return 80
        } else if sleep > 9 && sleep <= 10 {
            // 9-10 hours: 85 points
            return 85
        } else if sleep >= 5 && sleep < 6 {
            // 5-6 hours: 60 points
            return 60
        } else if sleep > 10 {
            // >10 hours: 70 points
            return 70
        } else {
            // <5 hours: very low score
            return max(20, Int(sleep * 10))
        }
    }
    
    // Stress Score: 0-100
    private func calculateStressScore(stress: UserHealthData.LifestyleCategory?) -> Int? {
        guard let stress = stress else { return nil }
        
        switch stress.preset.lowercased() {
        case "none", "very_low":
            return 100
        case "low", "minimal":
            return 85
        case "moderate", "average":
            return 65
        case "high":
            return 40
        case "very_high", "extreme":
            return 20
        default:
            return 50
        }
    }
    
    // Save health score to Firestore
    func saveHealthScore(_ score: Int) async {
        guard let userId = currentUserId else {
            await MainActor.run {
                errorMessage = "User not authenticated"
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let healthScore = HealthScore(score: score, lastUpdated: Date())
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            let data = try encoder.encode(healthScore)
            let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            // Convert Date to Timestamp for Firestore
            var firestoreDict = dictionary
            if let timestamp = dictionary["lastUpdated"] as? TimeInterval {
                firestoreDict["lastUpdated"] = Timestamp(seconds: Int64(timestamp), nanoseconds: 0)
            }
            
            try await db.collection("users").document(userId).setData(["healthScore": firestoreDict], merge: true)
            
            await MainActor.run {
                self.currentScore = score
                self.lastUpdated = Date()
                self.isLoading = false
                print("✅ Health score saved: \(score)")
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                print("😡 Error saving health score: \(error.localizedDescription)")
            }
        }
    }
    
    // Load health score from Firestore
    func loadHealthScore() async {
        guard let userId = currentUserId else {
            await MainActor.run {
                errorMessage = "User not authenticated"
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            guard let data = document.data(),
                  let healthScoreData = data["healthScore"] as? [String: Any] else {
                await MainActor.run {
                    self.isLoading = false
                }
                return
            }
            
            // Convert Firestore Timestamp to Date
            var jsonData = healthScoreData
            if let timestamp = healthScoreData["lastUpdated"] as? Timestamp {
                jsonData["lastUpdated"] = timestamp.dateValue().timeIntervalSince1970
            }
            
            let dataToDecode = try JSONSerialization.data(withJSONObject: jsonData)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let healthScore = try decoder.decode(HealthScore.self, from: dataToDecode)
            
            await MainActor.run {
                self.currentScore = healthScore.score
                self.lastUpdated = healthScore.lastUpdated
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                print("😡 Error loading health score: \(error.localizedDescription)")
            }
        }
    }
}

