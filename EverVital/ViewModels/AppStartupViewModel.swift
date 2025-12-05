import Foundation
import FirebaseAuth
import FirebaseFirestore
import Observation

@Observable
class AppStartupViewModel {
    var shouldShowDashboard = false
    var isLoading = true
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    func checkUserStatus() {
        guard Auth.auth().currentUser != nil else {
            isLoading = false
            shouldShowDashboard = false
            return
        }
        
        checkOnboardingStatus()
    }
    
    private func checkOnboardingStatus() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            shouldShowDashboard = false
            return
        }
        
        Task {
            do {
                let document = try await db.collection("users").document(userId).getDocument()
                
                guard let data = document.data() else {
                    await MainActor.run {
                        self.shouldShowDashboard = false
                        self.isLoading = false
                    }
                    return
                }
                
                // Check all 3 flags
                let surveyCompleted = data["surveyCompleted"] as? Bool ?? false
                let healthKitEnabled = data["healthKitEnabled"] as? Bool ?? false
                let hasLifeExpectancy = (data["lifeExpectancy"] as? [String: Any]) != nil
                
                // If all 3 are true, skip HomeView and go to Dashboard
                if surveyCompleted && healthKitEnabled && hasLifeExpectancy {
                    await MainActor.run {
                        self.shouldShowDashboard = true
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.shouldShowDashboard = false
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.shouldShowDashboard = false
                    self.isLoading = false
                }
            }
        }
    }
}

