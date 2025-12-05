import Foundation
import HealthKit
import FirebaseAuth
import FirebaseFirestore
import Observation

@Observable
class HealthKitViewModel {
    var isAuthorized = false
    var isLoading = false
    var errorMessage: String?
    
    private let healthStore = HKHealthStore()
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device"
            return
        }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            errorMessage = "Failed to initialize HealthKit types"
            return
        }
        
        let typesToRead: Set<HKObjectType> = [stepType, heartRateType, sleepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.isAuthorized = success
                    if success {
                        // Mark HealthKit as enabled immediately when authorized
                        self.markHealthKitEnabled()
                        self.readHealthData()
                    }
                }
            }
        }
    }
    
    func readHealthData() {
        guard currentUserId != nil else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let group = DispatchGroup()
        var steps: Int = 0
        var heartRate: Double = 0
        var sleepHours: Double = 0
        
        // Read step count - 7-day average (fallback to 30-day, then today)
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            group.enter()
            let calendar = Calendar.current
            let now = Date()
            
            // Helper function to try queries in sequence
            func try7DayAverage() {
                let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
                let predicate7Day = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)
                
                let query7Day = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate7Day, options: .cumulativeSum) { (_, result, error) in
                    if let sum = result?.sumQuantity() {
                        let totalSteps = Int(sum.doubleValue(for: HKUnit.count()))
                        if totalSteps > 0 {
                            // Calculate average (divide by 7)
                            steps = totalSteps / 7
                            group.leave()
                            return
                        }
                    }
                    // Fallback to 30-day
                    try30DayAverage()
                }
                healthStore.execute(query7Day)
            }
            
            func try30DayAverage() {
                let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
                let predicate30Day = HKQuery.predicateForSamples(withStart: thirtyDaysAgo, end: now, options: .strictStartDate)
                
                let query30Day = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate30Day, options: .cumulativeSum) { (_, result, error) in
                    if let sum = result?.sumQuantity() {
                        let totalSteps = Int(sum.doubleValue(for: HKUnit.count()))
                        if totalSteps > 0 {
                            // Calculate average (divide by 30)
                            steps = totalSteps / 30
                            group.leave()
                            return
                        }
                    }
                    // Fallback to today
                    tryTodaySteps()
                }
                healthStore.execute(query30Day)
            }
            
            func tryTodaySteps() {
                let startOfDay = calendar.startOfDay(for: now)
                let predicateToday = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
                
                let queryToday = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicateToday, options: .cumulativeSum) { (_, result, error) in
                    if let sum = result?.sumQuantity() {
                        steps = Int(sum.doubleValue(for: HKUnit.count()))
                    }
                    group.leave()
                }
                healthStore.execute(queryToday)
            }
            
            // Start with 7-day average
            try7DayAverage()
        }
        
        // Read heart rate (most recent)
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            group.enter()
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (_, samples, error) in
                if let sample = samples?.first as? HKQuantitySample {
                    heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                }
                group.leave()
            }
            healthStore.execute(query)
        }
        
        // Read sleep hours (last 24 hours)
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            group.enter()
            let calendar = Calendar.current
            let now = Date()
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)
            
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (_, samples, error) in
                var totalSleep: TimeInterval = 0
                if let samples = samples {
                    for sample in samples {
                        if let categorySample = sample as? HKCategorySample {
                            let value = categorySample.value
                            if #available(iOS 16.0, *) {
                                // Sum all asleep categories (core, deep, REM, unspecified)
                                if value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                                   value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                                   value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                                   value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                                    totalSleep += categorySample.endDate.timeIntervalSince(categorySample.startDate)
                                }
                            } else {
                                // Fallback for older iOS versions
                                if value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                                    totalSleep += categorySample.endDate.timeIntervalSince(categorySample.startDate)
                                }
                            }
                        }
                    }
                }
                sleepHours = totalSleep / 3600.0
                group.leave()
            }
            healthStore.execute(query)
        }
        
        group.notify(queue: .main) {
            // Only save sleep hours if > 0 (valid data)
            let validSleepHours = sleepHours > 0 ? sleepHours : 0
            self.saveHealthKitData(steps: steps, heartRate: heartRate, sleepHours: validSleepHours)
        }
    }
    
    private func saveHealthKitData(steps: Int, heartRate: Double, sleepHours: Double) {
        guard let userId = currentUserId else {
            isLoading = false
            errorMessage = "User not authenticated"
            return
        }
        
        let data: [String: Any] = [
            "appleSteps": steps,
            "appleHeartRate": heartRate,
            "appleSleepHours": sleepHours,
            "lastUpdated": Timestamp(date: Date())
        ]
        
        Task {
            do {
                // Save HealthKit data and mark HealthKit as enabled
                try await db.collection("users").document(userId).setData([
                    "healthKitData": data,
                    "healthKitEnabled": true
                ], merge: true)
                await MainActor.run {
                    self.isLoading = false
                    print("✅ HealthKit data saved successfully!")
                    
                    // Trigger health score recalculation after HealthKit data is saved
                    NotificationCenter.default.post(name: NSNotification.Name("HealthKitDataUpdated"), object: nil)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func markHealthKitEnabled() {
        guard let userId = currentUserId else { return }
        
        Task {
            do {
                try await db.collection("users").document(userId).setData(["healthKitEnabled": true], merge: true)
                print("✅ HealthKit enabled flag set to true")
            } catch {
                print("😡 Error setting healthKitEnabled flag: \(error.localizedDescription)")
            }
        }
    }
}

