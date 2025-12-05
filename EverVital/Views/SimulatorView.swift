import SwiftUI

struct SimulatorView: View {
    let baselineLifeExpectancy: Double
    let impactModel: ImpactModel
    let baselineLifestyle: LifestyleSurveyModel
    
    @State private var sleepHours: Double
    @State private var dailySteps: Double
    @State private var alcoholPerWeek: Double
    @State private var smokingIntensity: Double
    @State private var exerciseDays: Double
    
    @State private var simulatedLifeExpectancy: Double = 0
    @State private var simulatedRange: String = ""
    
    init(baselineLifeExpectancy: Double, impactModel: ImpactModel, baselineLifestyle: LifestyleSurveyModel) {
        self.baselineLifeExpectancy = baselineLifeExpectancy
        self.impactModel = impactModel
        self.baselineLifestyle = baselineLifestyle
        
        // Initialize sliders with baseline values
        _sleepHours = State(initialValue: baselineLifestyle.sleepHours)
        _dailySteps = State(initialValue: Double(baselineLifestyle.dailySteps))
        _alcoholPerWeek = State(initialValue: baselineLifestyle.alcoholPerWeek)
        _smokingIntensity = State(initialValue: baselineLifestyle.smokingIntensity)
        _exerciseDays = State(initialValue: Double(baselineLifestyle.exerciseDays))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Bell Curve Graph
                VStack(alignment: .leading, spacing: 12) {
                    Text("Life Expectancy Distribution")
                        .font(.title2)
                        .bold()
                    
                    BellCurveSimulatorGraph(
                        simulatedLifeExpectancy: simulatedLifeExpectancy,
                        baselineLifeExpectancy: baselineLifeExpectancy
                    )
                    .frame(height: 250)
                    .padding(.vertical, 8)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // Simulated Life Expectancy Display
                VStack(spacing: 8) {
                    Text("Simulated Life Expectancy")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(simulatedRange)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // Sliders Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Adjust Lifestyle Factors")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    // Sleep Hours Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Sleep Hours")
                                .font(.headline)
                            Spacer()
                            Text("\(sleepHours, specifier: "%.1f") hrs")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $sleepHours, in: 4...10, step: 0.5)
                            .onChange(of: sleepHours) { _, _ in
                                updateSimulation()
                            }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Daily Steps Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Daily Steps")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(dailySteps)) steps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $dailySteps, in: 0...20000, step: 500)
                            .onChange(of: dailySteps) { _, _ in
                                updateSimulation()
                            }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Alcohol Per Week Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Alcohol (units/week)")
                                .font(.headline)
                            Spacer()
                            Text("\(alcoholPerWeek, specifier: "%.1f") units")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $alcoholPerWeek, in: 0...25, step: 0.5)
                            .onChange(of: alcoholPerWeek) { _, _ in
                                updateSimulation()
                            }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Smoking Intensity Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Smoking Intensity")
                                .font(.headline)
                            Spacer()
                            Text(smokingIntensity == 0 ? "None" : smokingIntensity <= 3 ? "Light" : smokingIntensity <= 7 ? "Moderate" : "Heavy")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $smokingIntensity, in: 0...10, step: 0.5)
                            .onChange(of: smokingIntensity) { _, _ in
                                updateSimulation()
                            }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Exercise Days Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Exercise Days/Week")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(exerciseDays)) days")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $exerciseDays, in: 0...7, step: 1)
                            .onChange(of: exerciseDays) { _, _ in
                                updateSimulation()
                            }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                // Reset Button
                Button {
                    resetToBaseline()
                } label: {
                    Text("Reset to Baseline")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    Image("evervital-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 44)
                    Text("Life Expectancy Simulator")
                        .font(.title2)
                        .bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, -16)
            }
        }
        .onAppear {
            updateSimulation()
        }
    }
    
    private func updateSimulation() {
        // Calculate deltas from baseline
        let sleepDelta = sleepHours - baselineLifestyle.sleepHours
        let stepsDelta = dailySteps - Double(baselineLifestyle.dailySteps)
        let alcoholDelta = alcoholPerWeek - baselineLifestyle.alcoholPerWeek
        let smokingDelta = smokingIntensity - baselineLifestyle.smokingIntensity
        let exerciseDelta = exerciseDays - Double(baselineLifestyle.exerciseDays)
        
        // Calculate simulated life expectancy
        simulatedLifeExpectancy = baselineLifeExpectancy
            + (sleepDelta * impactModel.sleepPerHourGain)
            + ((stepsDelta / 1000.0) * impactModel.stepsPer1000Gain)
            - (alcoholDelta * impactModel.alcoholPerUnitLoss)
            - (smokingDelta * impactModel.smokingPerLevelLoss)
            + (exerciseDelta * impactModel.exercisePerDayGain)
        
        // Ensure reasonable bounds
        simulatedLifeExpectancy = max(50, min(120, simulatedLifeExpectancy))
        
        // Calculate range (±2 years)
        let min = Int(floor(simulatedLifeExpectancy - 2))
        let max = Int(ceil(simulatedLifeExpectancy + 2))
        simulatedRange = "\(min)–\(max) years"
    }
    
    private func resetToBaseline() {
        sleepHours = baselineLifestyle.sleepHours
        dailySteps = Double(baselineLifestyle.dailySteps)
        alcoholPerWeek = baselineLifestyle.alcoholPerWeek
        smokingIntensity = baselineLifestyle.smokingIntensity
        exerciseDays = Double(baselineLifestyle.exerciseDays)
        updateSimulation()
    }
}

// Bell Curve Graph for Simulator
struct BellCurveSimulatorGraph: View {
    let simulatedLifeExpectancy: Double
    let baselineLifeExpectancy: Double
    
    private let mean: Double = 78.0
    private let standardDeviation: Double = 10.0
    private let minAge: Double = 40
    private let maxAge: Double = 110
    
    private var bellCurveData: [(x: Double, y: Double)] {
        var data: [(x: Double, y: Double)] = []
        
        for x in stride(from: minAge, through: maxAge, by: 1) {
            let y = gaussian(x: x, mean: mean, stdDev: standardDeviation)
            data.append((x: x, y: y))
        }
        
        // Normalize Y values
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
        GeometryReader { geometry in
            ZStack {
                // Bell curve
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let data = bellCurveData
                    
                    guard !data.isEmpty else { return }
                    
                    let xScale = width / (maxAge - minAge)
                    let yScale = height * 0.8 // Leave some padding
                    
                    let firstPoint = CGPoint(
                        x: (data[0].x - minAge) * xScale,
                        y: height - (data[0].y * yScale)
                    )
                    path.move(to: firstPoint)
                    
                    for point in data.dropFirst() {
                        let cgPoint = CGPoint(
                            x: (point.x - minAge) * xScale,
                            y: height - (point.y * yScale)
                        )
                        path.addLine(to: cgPoint)
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
                
                // Baseline marker (gray)
                if baselineLifeExpectancy >= minAge && baselineLifeExpectancy <= maxAge {
                    let baselineX = (baselineLifeExpectancy - minAge) / (maxAge - minAge) * geometry.size.width
                    let markerHeight = geometry.size.height * 0.7 // Shorten to 70% of height
                    let markerTop = geometry.size.height * 0.15 // Start 15% from top
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 2, height: markerHeight)
                        .position(x: baselineX, y: markerTop + markerHeight / 2)
                }
                
                // Simulated marker (red, thicker)
                if simulatedLifeExpectancy >= minAge && simulatedLifeExpectancy <= maxAge {
                    let simulatedX = (simulatedLifeExpectancy - minAge) / (maxAge - minAge) * geometry.size.width
                    let markerHeight = geometry.size.height * 0.7 // Shorten to 70% of height
                    let markerTop = geometry.size.height * 0.15 // Start 15% from top
                    
                    VStack(spacing: 4) {
                        Text("You")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                            .padding(4)
                            .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 4))
                        
                        Capsule()
                            .fill(Color.red)
                            .frame(width: 4, height: markerHeight)
                    }
                    .position(x: simulatedX, y: markerTop + markerHeight / 2)
                }
                
                // X-axis labels
                VStack {
                    Spacer()
                    HStack {
                        Text("\(Int(minAge))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(maxAge))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}

#Preview {
    SimulatorView(
        baselineLifeExpectancy: 78.0,
        impactModel: ImpactModel.default,
        baselineLifestyle: LifestyleSurveyModel()
    )
}

