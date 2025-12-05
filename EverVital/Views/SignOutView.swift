import SwiftUI
import FirebaseAuth

struct SignOutView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isSigningOut = false
    
    var onSignOut: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 64, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.red)
                .padding(.top, 40)
            
            Text("Sign Out")
                .font(.title)
                .bold()
            
            Text("Tap below to sign out of your account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                signOut()
            } label: {
                HStack {
                    if isSigningOut {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(isSigningOut ? "Signing Out..." : "Sign Out")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(isSigningOut)
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    Image("evervital-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 44)
                    Text("Sign Out")
                        .font(.title2)
                        .bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, -16)
            }
        }
    }
    
    private func signOut() {
        isSigningOut = true
        
        Task { @MainActor in
            do {
                try Auth.auth().signOut()
                print("✅ Signed out successfully")
                // Call onSignOut immediately to update UI
                onSignOut()
            } catch {
                print("😡 Error signing out: \(error.localizedDescription)")
                isSigningOut = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignOutView(onSignOut: {})
    }
}

