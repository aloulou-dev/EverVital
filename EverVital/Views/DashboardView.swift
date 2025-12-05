import SwiftUI
import Charts
import Combine
import FirebaseAuth
import FirebaseFirestore

struct DashboardView: View {
    @State private var minYears: Int?
    @State private var maxYears: Int?
    @State private var recommendations: [String] = []
    @State private var reasoning: String = ""
    @State private var isLoading = true
    @State private var showSurvey = false
    @State private var showSignOut = false
    @State private var lifeExpectancyViewModel = LifeExpectancyViewModel()
    @State private var isRecalculating = false
    @State private var healthScoreViewModel = HealthScoreViewModel()
    
    var onSignOut: () -> Void = {}
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    @State private var showHealthKit = false
    @State private var healthKitEnabled = false
    @State private var showSimulator = false
    
    var body: some View {
        NavigationStack {
            if isLoading || isRecalculating {
                VStack(spacing: 16) {
                    ProgressView()
                    if isRecalculating {
                        Text("Recalculating life expectancy...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Health Score Card
                        if let score = healthScoreViewModel.currentScore {
                            HealthScoreCard(score: score)
                        }
                        
                        // Life Expectancy Range
                        if let min = minYears, let max = maxYears {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Expected Lifespan")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                Text("\(min)–\(max) years")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(.blue)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            
                            // Bell Curve Chart (Tappable)
                            Button {
                                showSimulator = true
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Life Expectancy Distribution")
                                                .font(.title2)
                                                .bold()
                                            
                                            Text("Tap to open Simulator")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    BellCurveChart(userLifeExpectancy: (min + max) / 2)
                                        .frame(height: 250)
                                        .padding(.vertical, 8)
                                    
                                    // Summary text
                                    Text(bellCurveSummary(userLifeExpectancy: (min + max) / 2))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Recommendations Section
                        if !recommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recommendations")
                                    .font(.title2)
                                    .bold()
                                
                                ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(index + 1).")
                                            .font(.headline)
                                            .foregroundStyle(.blue)
                                            .frame(width: 30, alignment: .leading)
                                        
                                        Text(recommendation)
                                            .font(.body)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Reasoning Section
                        if !reasoning.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Reasoning")
                                    .font(.title2)
                                    .bold()
                                
                                ScrollView {
                                    Text(reasoning)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxHeight: 300)
                            }
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Update Action Buttons
                        VStack(spacing: 12) {
                            Button {
                                showSurvey = true
                            } label: {
                                Text("Update Lifestyle Survey")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            
                            Button {
                                showHealthKit = true
                            } label: {
                                HStack {
                                    if healthKitEnabled {
                                        Image(systemName: "checkmark.circle.fill")
                                    } else {
                                        Image("evervital-logo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 48)
                                    }
                                    Text(healthKitEnabled ? "Manage Health Data" : "Connect Health Data")
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                            .buttonStyle(.bordered)
                            .tint(healthKitEnabled ? .green : .blue)
                            
                            Button {
                                recalculateLifeExpectancy()
                            } label: {
                                Text("Recalculate Life Expectancy")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }
                    }
                    .padding()
                }
                .navigationBarBackButtonHidden(true)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 12) {
                            Image("evervital-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 44)
                            Text("Dashboard")
                                .font(.title2)
                                .bold()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, -16)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showSignOut = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }
                .navigationDestination(isPresented: $showSurvey) {
                    HealthSurveyView(onSaveComplete: {
                        // After saving survey, recalculate life expectancy and health score
                        recalculateLifeExpectancy()
                        Task {
                            await recalculateHealthScore()
                        }
                    })
                }
                .navigationDestination(isPresented: $showHealthKit) {
                    HealthPermissionView()
                        .onAppear {
                            // Reload HealthKit status when returning
                            loadHealthKitStatus()
                        }
                }
                .navigationDestination(isPresented: $showSimulator) {
                    SimulatorContainerView()
                }
                .navigationDestination(isPresented: $showSignOut) {
                    SignOutView(onSignOut: onSignOut)
                }
            }
        }
        .onAppear {
            loadLifeExpectancy()
            loadHealthKitStatus()
            Task {
                await loadAndCalculateHealthScore()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HealthKitDataUpdated"))) { _ in
            loadHealthKitStatus()
            Task {
                await recalculateHealthScore()
            }
        }
    }
    
    private func loadAndCalculateHealthScore() async {
        // First try to load existing score
        await healthScoreViewModel.loadHealthScore()
        
        // Then recalculate to ensure it's up to date
        await recalculateHealthScore()
    }
    
    private func recalculateHealthScore() async {
        guard let userId = currentUserId else { return }
        
        do {
            // Fetch user data
            let document = try await db.collection("users").document(userId).getDocument()
            guard let data = document.data() else { return }
            
            // Get survey data
            var userHealthData = UserHealthData()
            if let surveyData = data["surveyData"] as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: surveyData)
                userHealthData = try JSONDecoder().decode(UserHealthData.self, from: jsonData)
            }
            
            // Get HealthKit data
            let healthKitData = data["healthKitData"] as? [String: Any]
            
            // Calculate score
            let score = healthScoreViewModel.calculateHealthScore(
                from: userHealthData,
                healthKitData: healthKitData
            )
            
            // Save score
            await healthScoreViewModel.saveHealthScore(score)
        } catch {
            print("😡 Error recalculating health score: \(error.localizedDescription)")
        }
    }
    
    private func loadLifeExpectancy() {
        guard let userId = currentUserId else {
            isLoading = false
            return
        }
        
        Task {
            do {
                let document = try await db.collection("users").document(userId).getDocument()
                
                guard let data = document.data(),
                      let lifeExpectancy = data["lifeExpectancy"] as? [String: Any] else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                    return
                }
                
                await MainActor.run {
                    self.minYears = lifeExpectancy["min"] as? Int
                    self.maxYears = lifeExpectancy["max"] as? Int
                    self.recommendations = lifeExpectancy["recommendations"] as? [String] ?? []
                    self.reasoning = lifeExpectancy["reasoning"] as? String ?? ""
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func recalculateLifeExpectancy() {
        isRecalculating = true
        showSurvey = false // Dismiss the survey view
        
        // Calculate new life expectancy
        lifeExpectancyViewModel.calculateLifeExpectancy()
        
        // Monitor when calculation completes
        Task {
            // Wait for calculation to complete
            while lifeExpectancyViewModel.isLoading {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Check if save was successful
            if lifeExpectancyViewModel.didSaveSuccessfully {
                // Reload the dashboard data
                await MainActor.run {
                    loadLifeExpectancy()
                    isRecalculating = false
                }
            } else {
                // If there was an error, just reload anyway
                await MainActor.run {
                    loadLifeExpectancy()
                    isRecalculating = false
                }
            }
        }
    }
    
    private func bellCurveSummary(userLifeExpectancy: Int) -> String {
        let mean = 78.0
        let difference = Double(userLifeExpectancy) - mean
        
        if abs(difference) <= 2 {
            return "You are average"
        } else if difference > 0 {
            return "You are above average"
        } else {
            return "You are below average"
        }
    }
    
    private func loadHealthKitStatus() {
        guard let userId = currentUserId else { return }
        
        Task {
            do {
                let document = try await db.collection("users").document(userId).getDocument()
                if let data = document.data() {
                    await MainActor.run {
                        self.healthKitEnabled = data["healthKitEnabled"] as? Bool ?? false
                    }
                }
            } catch {
                print("Error loading HealthKit status: \(error.localizedDescription)")
            }
        }
    }
}

// Bell Curve Chart View
struct BellCurveChart: View {
    let userLifeExpectancy: Int
    
    private let mean: Double = 78.0
    private let standardDeviation: Double = 10.0
    
    private var bellCurveData: [(x: Int, y: Double)] {
        var data: [(x: Int, y: Double)] = []
        
        for x in 40...110 {
            let y = gaussian(x: Double(x), mean: mean, stdDev: standardDeviation)
            data.append((x: x, y: y))
        }
        
        // Normalize Y values to 0-1 range for better visualization
        if let maxY = data.map(\.y).max(), maxY > 0 {
            return data.map { (x: $0.x, y: $0.y / maxY) }
        }
        
        return data
    }
    
    private func gaussian(x: Double, mean: Double, stdDev: Double) -> Double {
        let coefficient = 1.0 / (stdDev * sqrt(2.0 * .pi))
        let exponent = -0.5 * pow((x - mean) / stdDev, 2)
        return coefficient * exp(exponent)
    }
    
    var body: some View {
        Chart {
            // Bell curve line
            ForEach(bellCurveData, id: \.x) { point in
                LineMark(
                    x: .value("Age", point.x),
                    y: .value("Probability", point.y)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
            }
            
            // User's life expectancy marker
            RuleMark(x: .value("Your Life Expectancy", userLifeExpectancy))
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .annotation(position: .top, alignment: .center) {
                    Text("You")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                        .padding(4)
                        .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 4))
                }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 10)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
            }
        }
        .chartXScale(domain: 40...110)
        .padding()
    }
}

// Health Score Card View
struct HealthScoreCard: View {
    let score: Int
    
    private var scoreColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var scoreLabel: String {
        if score >= 80 {
            return "Excellent"
        } else if score >= 60 {
            return "Good"
        } else {
            return "Needs Improvement"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Health Score")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(score)/100")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(scoreColor)
                    
                    Text(scoreLabel)
                        .font(.subheadline)
                        .foregroundStyle(scoreColor.opacity(0.8))
                }
                
                Spacer()
                
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100.0)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: score)
                    
                    Text("\(score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(scoreColor)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
}

