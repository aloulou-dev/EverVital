import SwiftUI
import Combine
import FirebaseAuth

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showSurvey = false
    @State private var showHealthKit = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image("evervital-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 128)
                    .padding(.top, 40)
                
                Text("Welcome to EverVital")
                    .font(.title)
                    .bold()
                
                Text("Track your health and discover your life expectancy")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    // Survey Button
                    Button {
                        showSurvey = true
                    } label: {
                        HStack {
                            Image(systemName: viewModel.surveyCompleted ? "checkmark.circle.fill" : "list.clipboard.fill")
                            Text(viewModel.surveyCompleted ? "Survey Completed" : "Complete Health Survey")
                            Spacer()
                            if viewModel.surveyCompleted {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .padding()
                        .foregroundStyle(viewModel.surveyCompleted ? .white : .primary)
                        .background(
                            viewModel.surveyCompleted 
                                ? Color.green.opacity(0.8) 
                                : Color.clear
                        )
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // HealthKit Button
                    Button {
                        showHealthKit = true
                    } label: {
                        HStack {
                            if viewModel.healthKitEnabled {
                                Image(systemName: "checkmark.circle.fill")
                            } else {
                                Image("evervital-logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 48)
                            }
                            Text(viewModel.healthKitEnabled ? "Health Data Connected" : "Connect Apple Health")
                            Spacer()
                            if viewModel.healthKitEnabled {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .padding()
                        .foregroundStyle(viewModel.healthKitEnabled ? .white : .primary)
                        .background(
                            viewModel.healthKitEnabled 
                                ? Color.green.opacity(0.8) 
                                : Color.clear
                        )
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    NavigationLink(destination: DashboardView()) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("View Dashboard")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(role: .destructive) {
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        print("Error signing out: \(error)")
                    }
                } label: {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 12) {
                        Image("evervital-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 44)
                        Text("EverVital")
                            .font(.title2)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, -16)
                }
            }
            .navigationDestination(isPresented: $showSurvey) {
                HealthSurveyView(onSaveComplete: {
                    // Reload completion status after survey is saved
                    viewModel.loadCompletionStatus()
                })
            }
            .navigationDestination(isPresented: $showHealthKit) {
                HealthPermissionView()
                    .onAppear {
                        // Reload completion status when returning from HealthKit view
                        viewModel.loadCompletionStatus()
                    }
            }
            .onAppear {
                viewModel.loadCompletionStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HealthKitDataUpdated"))) { _ in
                // Reload completion status when HealthKit data is updated
                viewModel.loadCompletionStatus()
            }
        }
    }
}

#Preview {
    HomeView()
}

