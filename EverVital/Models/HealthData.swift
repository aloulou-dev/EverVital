//
//  HealthData.swift
//  EverVital
//
//  Created by Malek Aloulou on 12/2/25.
//

import Foundation
import HealthKit

struct HealthData: Codable {
    var steps: Double?
    var sleepHours: Double?
    var heartRate: Double? // average resting heart rate
    var activeEnergyBurned: Double? // in kilocalories
    var lastUpdated: Date
    
    init(steps: Double? = nil,
         sleepHours: Double? = nil,
         heartRate: Double? = nil,
         activeEnergyBurned: Double? = nil,
         lastUpdated: Date = Date()) {
        self.steps = steps
        self.sleepHours = sleepHours
        self.heartRate = heartRate
        self.activeEnergyBurned = activeEnergyBurned
        self.lastUpdated = lastUpdated
    }
}

// Helper for HealthKit types
enum HealthDataType {
    case steps
    case sleep
    case heartRate
    case activeEnergy
    
    var hkSampleType: HKSampleType? {
        switch self {
        case .steps:
            return HKQuantityType.quantityType(forIdentifier: .stepCount)
        case .sleep:
            return HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
        case .heartRate:
            return HKQuantityType.quantityType(forIdentifier: .heartRate)
        case .activeEnergy:
            return HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        }
    }
}

