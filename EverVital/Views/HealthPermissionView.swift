import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HealthPermissionView: View {
    @State private var viewModel = HealthKitViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 64, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.red)
                .padding(.top, 40)
            
            Text("Connect Apple Health")
                .font(.title)
                .bold()
            
            Text("We'll read your step count, heart rate, and sleep data to provide more accurate life expectancy estimates.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if viewModel.isAuthorized {
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    
                    Text("HealthKit Connected")
                        .font(.headline)
                        .foregroundStyle(.green)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                        Text("Loading health data...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 16) {
                            Text("Your health data is connected and will be used for life expectancy calculations.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(role: .destructive) {
                                disconnectHealthKit()
                            } label: {
                                Text("Disconnect Health Data")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .onChange(of: viewModel.isLoading) { oldValue, newValue in
                    // When loading finishes, don't auto-dismiss - let user choose to disconnect or go back
                }
            } else {
                Button {
                    viewModel.requestAuthorization()
                } label: {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("Connect Apple Health")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(viewModel.isLoading)
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Health Permissions")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func disconnectHealthKit() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                let db = Firestore.firestore()
                try await db.collection("users").document(userId).setData(["healthKitEnabled": false], merge: true)
                
                await MainActor.run {
                    viewModel.isAuthorized = false
                    print("✅ HealthKit disconnected")
                }
            } catch {
                print("Error disconnecting HealthKit: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        HealthPermissionView()
    }
}

