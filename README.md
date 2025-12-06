# EverVital

EverVital is a health-focused iOS app that helps users understand their overall wellness and estimated life expectancy based on their personal data and daily habits. The app combines information from a detailed lifestyle survey with real metrics pulled from Apple Health, such as step count, heart rate, and sleep. Using this data, EverVital calculates a life expectancy range, generates a health score, and provides personalized recommendations. The dashboard gives users a clean view of their current health status, while the built-in simulator shows how specific lifestyle changes could impact their long-term health. The entire app is built with SwiftUI, uses Firebase for authentication and data storage, and relies on HealthKit for real-time health data integration.

## Features

### 🔐 Authentication
- User registration and login using Firebase Authentication
- Secure user session management
- Sign out functionality

### 📊 Health Survey
- Comprehensive health questionnaire covering:
  - Basic information (age, weight, height, sleep)
  - Lifestyle factors (smoking, alcohol, exercise, diet, stress)
  - Conditional follow-up questions based on responses
- Survey completion tracking
- Data persistence in Firebase Firestore

### 🏥 Apple Health Integration
- Seamless connection with Apple HealthKit
- Automatic data synchronization for:
  - **Step Count**: 7-day average (with fallback to 30-day or daily)
  - **Heart Rate**: Most recent reading
  - **Sleep Data**: 24-hour sleep analysis (supports iOS 16+ sleep categories)
- Real-time health data updates
- Privacy-compliant data access

### 📈 Life Expectancy Calculation
- Advanced algorithm that considers:
  - User demographics (age, weight, height)
  - Lifestyle factors (smoking, alcohol, exercise, diet, stress)
  - HealthKit data (steps, heart rate, sleep)
- Provides a realistic life expectancy range (min-max years)
- Detailed reasoning and personalized recommendations

### 📱 Dashboard
- **Health Score**: Visual representation of overall health status
- **Life Expectancy Display**: Clear presentation of expected lifespan range
- **Bell Curve Visualization**: Interactive chart showing life expectancy distribution
- **Simulator**: Explore how lifestyle changes affect life expectancy
- **Personalized Recommendations**: Actionable health improvement suggestions
- **Reasoning**: Explanation of how the calculation was derived

### 🎯 Health Score System
- Comprehensive scoring algorithm
- Visual health score card
- Real-time updates based on health data changes

## Tech Stack

- **Language**: Swift 5.0
- **Framework**: SwiftUI
- **Backend**: Firebase
  - Authentication
  - Firestore (NoSQL database)
- **Health Integration**: HealthKit
- **Charts**: Swift Charts
- **Architecture**: MVVM (Model-View-ViewModel)
- **Concurrency**: Swift Concurrency (async/await)

## Requirements

- iOS 16.0 or later
- Xcode 15.0 or later
- Swift 5.0+
- Active Apple Developer account (for HealthKit capabilities)
- Firebase project with:
  - Authentication enabled
  - Firestore database configured

## Setup Instructions

### 1. Clone the Repository
```bash
git clone <repository-url>
cd EverVital
```

### 2. Firebase Configuration

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable the following services:
   - **Authentication**: Email/Password provider
   - **Firestore Database**: Create a database in production mode
3. Download `GoogleService-Info.plist` from Firebase Console
4. Replace the existing `GoogleService-Info.plist` in the project

### 3. Xcode Configuration

1. Open `EverVital.xcodeproj` in Xcode
2. Select your development team in **Signing & Capabilities**
3. Add the **HealthKit** capability:
   - Select the EverVital target
   - Go to **Signing & Capabilities** tab
   - Click **+ Capability**
   - Add **HealthKit**
4. Ensure the following are configured:
   - `Info.plist` includes HealthKit privacy descriptions
   - `EverVital.entitlements` includes HealthKit entitlement

### 4. Build and Run

1. Select your target device or simulator
2. Build and run the project (⌘R)
3. Note: HealthKit features require a physical device (simulator has limited support)

## Project Structure

```
EverVital/
├── Models/
│   ├── HealthScore.swift          # Health score data model
│   ├── ImpactModel.swift          # Impact calculation models
│   ├── LifestyleSurveyModel.swift # Survey data structures
│   └── UserHealthData.swift       # User health data model
├── ViewModels/
│   ├── AppStartupViewModel.swift  # App initialization logic
│   ├── HealthKitViewModel.swift   # HealthKit integration
│   ├── HealthScoreViewModel.swift # Health score calculations
│   ├── HealthSurveyViewModel.swift # Survey management
│   ├── HomeViewModel.swift        # Home screen state
│   └── LifeExpectancyViewModel.swift # Life expectancy calculations
├── Views/
│   ├── ContentView.swift          # Main app entry point
│   ├── DashboardView.swift        # Main dashboard
│   ├── HealthPermissionView.swift # HealthKit permission screen
│   ├── HealthSurveyView.swift     # Health survey form
│   ├── HomeView.swift             # Home/onboarding screen
│   ├── SimulatorView.swift        # Life expectancy simulator
│   └── SignOutView.swift          # Sign out confirmation
├── Assets.xcassets/               # App icons and images
├── EverVitalApp.swift            # App entry point
├── Info.plist                    # App configuration
└── GoogleService-Info.plist      # Firebase configuration
```

## Key Components

### HealthKit Integration
The app requests read access to:
- Step count (HKQuantityTypeIdentifierStepCount)
- Heart rate (HKQuantityTypeIdentifierHeartRate)
- Sleep analysis (HKCategoryTypeIdentifierSleepAnalysis)

### Life Expectancy Algorithm
The calculation considers multiple factors:
- Base life expectancy by age and demographics
- Lifestyle adjustments (smoking, alcohol, exercise, diet, stress)
- Activity level (steps, heart rate)
- Sleep quality and duration
- Weight and BMI considerations

### Data Flow
1. User completes health survey → Saved to Firestore
2. User connects Apple Health → Data synced to Firestore
3. User calculates life expectancy → Algorithm processes all data
4. Results displayed on dashboard with recommendations

## Privacy & Security

- All health data is stored securely in Firebase Firestore
- HealthKit data access requires explicit user permission
- User authentication handled by Firebase
- Privacy descriptions included in Info.plist
- No health data is shared with third parties

## Development Notes

### HealthKit Testing
- HealthKit requires a physical iOS device
- Simulator has limited HealthKit support
- Test with real health data for accurate results

### Firebase Rules
Ensure your Firestore security rules are configured:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Future Enhancements

- [ ] Historical data tracking and trends
- [ ] Social features and sharing
- [ ] More detailed health metrics
- [ ] Integration with additional health apps
- [ ] Push notifications for health reminders
- [ ] Export health reports

## License

[Add your license information here]

## Author

Created by Malek Aloulou

## Support

For issues, questions, or contributions, please open an issue in the repository.

