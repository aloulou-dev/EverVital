import Foundation
import FirebaseAuth
import FirebaseFirestore
import Observation

@Observable
class HealthSurveyViewModel {
    var healthData = UserHealthData()
    var isLoading = false
    var errorMessage: String?
    var saveSuccess = false
    var additionalInfo: String = ""
    
    // Imperial units
    var weightLb: Double? = nil
    var heightFeet: Int? = nil
    var heightInches: Int? = nil
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    func saveSurveyData() {
        Task { @MainActor in
            guard let userId = currentUserId else {
                errorMessage = "User not authenticated"
                return
            }
            
            isLoading = true
            errorMessage = nil
            saveSuccess = false
            
            guard let success = await HealthSurveyViewModel.saveHealthData(
                healthData: healthData,
                userId: userId,
                weightLb: weightLb,
                heightFeet: heightFeet,
                heightInches: heightInches,
                additionalInfo: additionalInfo
            ) else {
                isLoading = false
                errorMessage = "Failed to save survey data"
                saveSuccess = false
                print("😡 Error: saving health data returned nil")
                return
            }
            
            isLoading = false
            if success {
                print("😎 Nice health data save!")
                saveSuccess = true
            } else {
                errorMessage = "Failed to save survey data"
                saveSuccess = false
            }
        }
    }
    
    static func saveHealthData(healthData: UserHealthData, userId: String, weightLb: Double?, heightFeet: Int?, heightInches: Int?, additionalInfo: String) async -> Bool? {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(healthData)
            var dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            // Add Imperial units (overwrite any metric versions)
            if let weightLb = weightLb {
                dictionary["weightLb"] = weightLb
                // Remove old metric weight if it exists
                dictionary.removeValue(forKey: "weight")
            }
            if let heightFeet = heightFeet {
                dictionary["heightFeet"] = heightFeet
            }
            if let heightInches = heightInches {
                dictionary["heightInches"] = heightInches
            }
            // Remove old metric height if it exists
            dictionary.removeValue(forKey: "height")
            
            // Debug: Print what we're saving
            print("💾 Saving survey data:")
            print("   Age: \(healthData.age ?? -1)")
            print("   Weight (lb): \(weightLb ?? -1)")
            print("   Height: \(heightFeet ?? -1)ft \(heightInches ?? -1)in")
            print("   Sleep: \(healthData.sleepHours ?? -1)")
            print("   Smoking: \(healthData.smoking?.preset ?? "nil")")
            print("   Alcohol: \(healthData.alcohol?.preset ?? "nil")")
            print("   Exercise: \(healthData.exercise?.preset ?? "nil")")
            print("   Diet: \(healthData.diet?.preset ?? "nil")")
            print("   Stress: \(healthData.stress?.preset ?? "nil")")
            print("   Additional Info: \(additionalInfo.isEmpty ? "none" : "provided")")
            
            let db = Firestore.firestore()
            let ref = db.collection("users").document(userId)
            
            // Save survey data, additional info, and mark survey as completed
            try await ref.setData([
                "surveyData": dictionary,
                "additionalInfo": additionalInfo,
                "surveyCompleted": true
            ], merge: true)
            print("✅ Survey data saved successfully!")
            return true
        } catch {
            print("😡 Error saving health data: \(error.localizedDescription)")
            return false
        }
    }
    
    func loadSurveyData() {
        print("📥 Loading survey data...")
        guard let userId = currentUserId else {
            print("😡 No user ID")
            errorMessage = "User not authenticated"
            return
        }
        
        print("👤 User ID: \(userId)")
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🔍 Fetching document from Firestore...")
                let document = try await db.collection("users").document(userId).getDocument()
                
                print("📄 Document exists: \(document.exists)")
                
                await MainActor.run {
                    self.isLoading = false
                    print("✅ isLoading set to false")
                }
                
                guard let data = document.data() else {
                    // No existing data - that's okay, just return with empty healthData
                    print("ℹ️ No existing survey data found - starting fresh")
                    return
                }
                
                // Load additional info and Imperial units
                await MainActor.run {
                    if let info = data["additionalInfo"] as? String {
                        self.additionalInfo = info
                    }
                }
                
                guard let surveyData = data["surveyData"] as? [String: Any] else {
                    // No survey data
                    return
                }
                
                // Load Imperial units from surveyData
                await MainActor.run {
                    if let weightLb = surveyData["weightLb"] as? Double {
                        self.weightLb = weightLb
                    } else if let weightKg = surveyData["weight"] as? Double {
                        // Convert old metric weight to lb
                        self.weightLb = weightKg / 0.453592
                    }
                    
                    if let feet = surveyData["heightFeet"] as? Int {
                        self.heightFeet = feet
                    }
                    if let inches = surveyData["heightInches"] as? Int {
                        self.heightInches = inches
                    } else if let heightCm = surveyData["height"] as? Double {
                        // Convert old metric height to feet+inches
                        let totalInches = heightCm / 2.54
                        self.heightFeet = Int(floor(totalInches / 12))
                        self.heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
                    }
                }
                
                print("📊 Found existing survey data, decoding...")
                let jsonData = try JSONSerialization.data(withJSONObject: surveyData)
                
                // Try to decode with new format first
                var decodedData: UserHealthData
                do {
                    decodedData = try JSONDecoder().decode(UserHealthData.self, from: jsonData)
                } catch {
                    // If that fails, try to migrate from old format (strings) to new format (LifestyleCategory)
                    print("⚠️ New format decode failed, attempting migration from old format...")
                    decodedData = UserHealthData()
                    
                    // Copy basic fields
                    if let age = surveyData["age"] as? Int { decodedData.age = age }
                    if let weight = surveyData["weight"] as? Double { decodedData.weight = weight }
                    if let height = surveyData["height"] as? Double { decodedData.height = height }
                    if let sleepHours = surveyData["sleepHours"] as? Double { decodedData.sleepHours = sleepHours }
                    
                    // Migrate old string format to new LifestyleCategory format
                    if let smoking = surveyData["smoking"] as? String {
                        decodedData.smoking = UserHealthData.LifestyleCategory(preset: smoking)
                    }
                    if let alcohol = surveyData["alcohol"] as? String {
                        decodedData.alcohol = UserHealthData.LifestyleCategory(preset: alcohol)
                    }
                    if let exercise = surveyData["exercise"] as? String {
                        decodedData.exercise = UserHealthData.LifestyleCategory(preset: exercise)
                    }
                    if let diet = surveyData["diet"] as? String {
                        decodedData.diet = UserHealthData.LifestyleCategory(preset: diet)
                    }
                    if let stress = surveyData["stress"] as? String {
                        decodedData.stress = UserHealthData.LifestyleCategory(preset: stress)
                    }
                }
                
                await MainActor.run {
                    self.healthData = decodedData
                    print("✅ Survey data loaded successfully")
                }
            } catch {
                print("😡 Error loading data: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    print("✅ isLoading set to false (error case)")
                    // Don't show error if document doesn't exist - that's normal for first-time users
                    if (error as NSError).code != 5 { // 5 = not found error
                        self.errorMessage = "Failed to load data: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

