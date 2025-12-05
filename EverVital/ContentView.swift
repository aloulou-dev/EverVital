import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var startupViewModel = AppStartupViewModel()
    @State private var isAuthenticated = false
    @State private var showSignUp = false
    @State private var viewKey = UUID()
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            if !isAuthenticated {
                NavigationStack {
                    VStack(spacing: 24) {
                        Image("evervital-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 112)
                            .padding(.top, 40)

                        Text("Welcome to EverVital")
                            .font(.title2).bold()

                        LoginView {
                            checkAuthState()
                        }

                        Button("Create an account") {
                            showSignUp = true
                        }
                        .buttonStyle(.borderless)
                        .padding(.bottom, 16)
                    }
                    .navigationDestination(isPresented: $showSignUp) {
                        SignUpView {
                            checkAuthState()
                        }
                    }
                }
                .id("login-\(viewKey)")
            } else if startupViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if startupViewModel.shouldShowDashboard {
                DashboardView(onSignOut: {
                    handleSignOut()
                })
                .id("dashboard-\(viewKey)")
            } else {
                HomeView()
                .id("home-\(viewKey)")
            }
        }
        .onAppear {
            checkAuthState()
            startupViewModel.checkUserStatus()
            // Listen for auth state changes
            authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
                Task { @MainActor in
                    let wasAuthenticated = isAuthenticated
                    isAuthenticated = user != nil
                    
                    if user != nil {
                        if !wasAuthenticated {
                            // User just logged in
                            startupViewModel.checkUserStatus()
                        }
                    } else {
                        // User signed out - reset everything
                        startupViewModel.shouldShowDashboard = false
                        startupViewModel.isLoading = false
                    }
                }
            }
        }
        .onDisappear {
            if let handle = authListenerHandle {
                Auth.auth().removeStateDidChangeListener(handle)
                authListenerHandle = nil
            }
        }
    }
    
    private func checkAuthState() {
        isAuthenticated = Auth.auth().currentUser != nil
    }
    
    private func handleSignOut() {
        // Reset all state immediately on main thread
        Task { @MainActor in
            isAuthenticated = false
            startupViewModel.shouldShowDashboard = false
            startupViewModel.isLoading = false
            // Force view refresh by resetting the startup view model and view key
            startupViewModel = AppStartupViewModel()
            viewKey = UUID() // Force view hierarchy reset
        }
    }
}

#Preview {
    ContentView()
}
