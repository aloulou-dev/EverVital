import Foundation
import FirebaseAuth
import FirebaseFirestore
import Observation

@Observable
class HomeViewModel {
    var surveyCompleted = false
    var healthKitEnabled = false
    var lifeExpectancyExists = false
    var isLoading = false
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    func loadCompletionStatus() {
        guard let userId = currentUserId else {
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let document = try await db.collection("users").document(userId).getDocument()
                
                guard let data = document.data() else {
                    await MainActor.run {
                        self.surveyCompleted = false
                        self.healthKitEnabled = false
                        self.lifeExpectancyExists = false
                        self.isLoading = false
                    }
                    return
                }
                
                await MainActor.run {
                    self.surveyCompleted = data["surveyCompleted"] as? Bool ?? false
                    self.healthKitEnabled = data["healthKitEnabled"] as? Bool ?? false
                    self.lifeExpectancyExists = (data["lifeExpectancy"] as? [String: Any]) != nil
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("😡 Error loading completion status: \(error.localizedDescription)")
                }
            }
        }
    }
}

