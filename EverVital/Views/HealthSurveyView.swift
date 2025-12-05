import SwiftUI

struct HealthSurveyView: View {
    @State private var viewModel = HealthSurveyViewModel()
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    var onSaveComplete: (() -> Void)? = nil
    
    var body: some View {
        Form {
                Section("Basic Information") {
                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("Years", value: $viewModel.healthData.age, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Weight (lb)")
                        Spacer()
                        TextField("lb", value: $viewModel.weightLb, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        HStack(spacing: 8) {
                            TextField("ft", value: $viewModel.heightFeet, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("ft")
                                .foregroundStyle(.secondary)
                            TextField("in", value: $viewModel.heightInches, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("in")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Average Hours of Sleep per Day")
                        Spacer()
                        TextField("Hours", value: $viewModel.healthData.sleepHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Smoking Section
                Section("Smoking") {
                    Picker("Status", selection: Binding(
                        get: { viewModel.healthData.smoking?.preset ?? "never" },
                        set: { newValue in
                            if viewModel.healthData.smoking == nil {
                                viewModel.healthData.smoking = UserHealthData.LifestyleCategory(preset: newValue)
                            } else {
                                viewModel.healthData.smoking?.preset = newValue
                            }
                            // Reset follow-up data when preset changes
                            if newValue != "current" && newValue != "former" {
                                viewModel.healthData.smoking?.followUpData = nil
                            }
                        }
                    )) {
                        Text("Never").tag("never")
                        Text("Former").tag("former")
                        Text("Current").tag("current")
                    }
                    
                    // Conditional follow-up for Current smokers
                    if viewModel.healthData.smoking?.preset == "current" {
                        Picker("Frequency", selection: Binding(
                            get: { viewModel.healthData.smoking?.followUpData?["frequency"] ?? "occasional" },
                            set: { newValue in
                                if viewModel.healthData.smoking?.followUpData == nil {
                                    viewModel.healthData.smoking?.followUpData = [:]
                                }
                                viewModel.healthData.smoking?.followUpData?["frequency"] = newValue
                            }
                        )) {
                            Text("Occasional").tag("occasional")
                            Text("Daily").tag("daily")
                            Text("Heavy").tag("heavy")
                        }
                    }
                    
                    // Conditional follow-up for Former smokers
                    if viewModel.healthData.smoking?.preset == "former" {
                        HStack {
                            Text("Years Smoked")
                            Spacer()
                            TextField("Years", text: Binding(
                                get: { viewModel.healthData.smoking?.followUpData?["yearsSmoked"] ?? "" },
                                set: { newValue in
                                    if viewModel.healthData.smoking?.followUpData == nil {
                                        viewModel.healthData.smoking?.followUpData = [:]
                                    }
                                    viewModel.healthData.smoking?.followUpData?["yearsSmoked"] = newValue
                                }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Quit (years ago)")
                            Spacer()
                            TextField("Years", text: Binding(
                                get: { viewModel.healthData.smoking?.followUpData?["yearsQuit"] ?? "" },
                                set: { newValue in
                                    if viewModel.healthData.smoking?.followUpData == nil {
                                        viewModel.healthData.smoking?.followUpData = [:]
                                    }
                                    viewModel.healthData.smoking?.followUpData?["yearsQuit"] = newValue
                                }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                    
                   
                    TextField("Additional details (optional)", text: Binding(
                        get: { viewModel.healthData.smoking?.optionalDetails ?? "" },
                        set: { viewModel.healthData.smoking?.optionalDetails = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }
                
                // Alcohol Section
                Section("Alcohol") {
                    Picker("Consumption Level", selection: Binding(
                        get: { viewModel.healthData.alcohol?.preset ?? "none" },
                        set: { newValue in
                            if viewModel.healthData.alcohol == nil {
                                viewModel.healthData.alcohol = UserHealthData.LifestyleCategory(preset: newValue)
                            } else {
                                viewModel.healthData.alcohol?.preset = newValue
                            }
                        }
                    )) {
                        Text("None").tag("none")
                        Text("Light").tag("light")
                        Text("Moderate").tag("moderate")
                        Text("Heavy").tag("heavy")
                    }
                    
                    // Conditional follow-up for all alcohol levels except "none"
                    if viewModel.healthData.alcohol?.preset != "none" {
                        Picker("Frequency", selection: Binding(
                            get: { viewModel.healthData.alcohol?.followUpData?["frequency"] ?? "occasional" },
                            set: { newValue in
                                if viewModel.healthData.alcohol?.followUpData == nil {
                                    viewModel.healthData.alcohol?.followUpData = [:]
                                }
                                viewModel.healthData.alcohol?.followUpData?["frequency"] = newValue
                            }
                        )) {
                            Text("Occasional").tag("occasional")
                            Text("Weekly").tag("weekly")
                            Text("Daily").tag("daily")
                        }
                        
                        HStack {
                            Text("Typical Drinks")
                            Spacer()
                            TextField("e.g., 1-2 glasses wine", text: Binding(
                                get: { viewModel.healthData.alcohol?.followUpData?["typicalDrinks"] ?? "" },
                                set: { newValue in
                                    if viewModel.healthData.alcohol?.followUpData == nil {
                                        viewModel.healthData.alcohol?.followUpData = [:]
                                    }
                                    viewModel.healthData.alcohol?.followUpData?["typicalDrinks"] = newValue
                                }
                            ))
                            .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    TextField("Additional details (optional)", text: Binding(
                        get: { viewModel.healthData.alcohol?.optionalDetails ?? "" },
                        set: { viewModel.healthData.alcohol?.optionalDetails = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }
                
                // Exercise Section
                Section("Exercise") {
                    Picker("Activity Level", selection: Binding(
                        get: { viewModel.healthData.exercise?.preset ?? "none" },
                        set: { newValue in
                            if viewModel.healthData.exercise == nil {
                                viewModel.healthData.exercise = UserHealthData.LifestyleCategory(preset: newValue)
                            } else {
                                viewModel.healthData.exercise?.preset = newValue
                            }
                        }
                    )) {
                        Text("None").tag("none")
                        Text("Light").tag("light")
                        Text("Moderate").tag("moderate")
                        Text("Intense").tag("intense")
                    }
                    
                    // Conditional follow-up for all exercise levels except "none"
                    if viewModel.healthData.exercise?.preset != "none" {
                        Picker("Frequency", selection: Binding(
                            get: { viewModel.healthData.exercise?.followUpData?["frequency"] ?? "occasional" },
                            set: { newValue in
                                if viewModel.healthData.exercise?.followUpData == nil {
                                    viewModel.healthData.exercise?.followUpData = [:]
                                }
                                viewModel.healthData.exercise?.followUpData?["frequency"] = newValue
                            }
                        )) {
                            Text("Occasional").tag("occasional")
                            Text("2-3 times/week").tag("2-3 times/week")
                            Text("4-5 times/week").tag("4-5 times/week")
                            Text("Daily").tag("daily")
                        }
                        
                        HStack {
                            Text("Type of Exercise")
                            Spacer()
                            TextField("e.g., Running, Weightlifting", text: Binding(
                                get: { viewModel.healthData.exercise?.followUpData?["type"] ?? "" },
                                set: { viewModel.healthData.exercise?.followUpData?["type"] = $0 }
                            ))
                            .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    TextField("Additional details (optional)", text: Binding(
                        get: { viewModel.healthData.exercise?.optionalDetails ?? "" },
                        set: { viewModel.healthData.exercise?.optionalDetails = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }
                
                // Diet Section
                Section("Diet") {
                    Picker("Diet Type", selection: Binding(
                        get: { viewModel.healthData.diet?.preset ?? "omnivore" },
                        set: { newValue in
                            if viewModel.healthData.diet == nil {
                                viewModel.healthData.diet = UserHealthData.LifestyleCategory(preset: newValue)
                            } else {
                                viewModel.healthData.diet?.preset = newValue
                            }
                        }
                    )) {
                        Text("Omnivore").tag("omnivore")
                        Text("Vegetarian").tag("vegetarian")
                        Text("Vegan").tag("vegan")
                        Text("Pescatarian").tag("pescatarian")
                        Text("Keto").tag("keto")
                        Text("Mediterranean").tag("mediterranean")
                    }
                    
                    TextField("Additional notes (optional)", text: Binding(
                        get: { viewModel.healthData.diet?.optionalDetails ?? "" },
                        set: { viewModel.healthData.diet?.optionalDetails = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }
                
                // Stress Section
                Section("Stress Level") {
                    Picker("Level", selection: Binding(
                        get: { viewModel.healthData.stress?.preset ?? "low" },
                        set: { newValue in
                            if viewModel.healthData.stress == nil {
                                viewModel.healthData.stress = UserHealthData.LifestyleCategory(preset: newValue)
                            } else {
                                viewModel.healthData.stress?.preset = newValue
                            }
                        }
                    )) {
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                    
                    TextField("Additional details (optional)", text: Binding(
                        get: { viewModel.healthData.stress?.optionalDetails ?? "" },
                        set: { viewModel.healthData.stress?.optionalDetails = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }
                
                // Additional Information Section
                Section("Additional Information (Optional)") {
                    TextEditor(text: $viewModel.additionalInfo)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if viewModel.additionalInfo.isEmpty {
                                    VStack {
                                        HStack {
                                            Text("Enter any extra context about your lifestyle, medical history, or habits that you think could impact your life expectancy. (Optional)")
                                                .foregroundStyle(.secondary)
                                                .padding(.top, 8)
                                                .padding(.leading, 4)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                }
                            },
                            alignment: .topLeading
                        )
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    Image("evervital-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 44)
                    Text("Health Survey")
                        .font(.title2)
                        .bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, -16)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    viewModel.saveSurveyData()
                }
                .disabled(viewModel.isLoading)
            }
        }
        .alert("Survey Saved", isPresented: Binding(
            get: { viewModel.saveSuccess },
            set: { _ in viewModel.saveSuccess = false }
        )) {
            Button("OK", role: .cancel) { 
                onSaveComplete?()
                dismiss() // Navigate back to HomeView
            }
        } message: {
            Text("Your health survey has been saved successfully.")
        }
        .onChange(of: viewModel.saveSuccess) { oldValue, newValue in
            if newValue && oldValue != newValue {
                // Save was successful, wait for user to dismiss alert before calling callback
                // The callback will be called when they tap OK
            }
        }
        .onAppear {
            viewModel.loadSurveyData()
        }
    }
}

#Preview {
    NavigationStack {
        HealthSurveyView()
    }
}
