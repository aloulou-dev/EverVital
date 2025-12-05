import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SimulatorContainerView: View {
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var baselineLifeExpectancy: Double?
    @State private var baselineLifestyle: LifestyleSurveyModel?
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading simulator data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let baseline = baselineLifeExpectancy, let lifestyle = baselineLifestyle {
                SimulatorView(
                    baselineLifeExpectancy: baseline,
                    impactModel: ImpactModel.default,
                    baselineLifestyle: lifestyle
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    
                    Text("Unable to Load Simulator")
                        .font(.title2)
                        .bold()
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("Please complete your health survey first to use the simulator.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            loadSimulatorData()
        }
    }
    
    private func loadSimulatorData() {
        guard let userId = currentUserId else {
            errorMessage = "User not authenticated"
            isLoading = false
            return
        }
        
        Task {
            do {
                let document = try await db.collection("users").document(userId).getDocument()
                guard let data = document.data() else {
                    await MainActor.run {
                        errorMessage = "No user data found"
                        isLoading = false
                    }
                    return
                }
                
                // Get baseline life expectancy (use midpoint of range)
                var baseline: Double?
                if let lifeExpectancy = data["lifeExpectancy"] as? [String: Any],
                   let min = lifeExpectancy["min"] as? Int,
                   let max = lifeExpectancy["max"] as? Int {
                    baseline = Double(min + max) / 2.0
                }
                
                // Get survey data and HealthKit data to build baseline lifestyle
                let surveyData = data["surveyData"] as? [String: Any]
                let healthKitData = data["healthKitData"] as? [String: Any]
                
                var userHealthData = UserHealthData()
                if let survey = surveyData {
                    let jsonData = try JSONSerialization.data(withJSONObject: survey)
                    userHealthData = try JSONDecoder().decode(UserHealthData.self, from: jsonData)
                }
                
                let healthKitSteps = healthKitData?["appleSteps"] as? Int
                let healthKitSleep = healthKitData?["appleSleepHours"] as? Double
                
                let lifestyle = LifestyleSurveyModel.from(
                    userData: userHealthData,
                    healthKitSteps: healthKitSteps,
                    healthKitSleep: healthKitSleep
                )
                
                await MainActor.run {
                    if let baseline = baseline {
                        self.baselineLifeExpectancy = baseline
                        self.baselineLifestyle = lifestyle
                    } else {
                        errorMessage = "Please calculate your life expectancy first"
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load data: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

