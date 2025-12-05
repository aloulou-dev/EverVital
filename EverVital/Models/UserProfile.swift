//
//  UserProfile.swift
//  EverVital
//
//  Created by Malek Aloulou on 12/2/25.
//

import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    let email: String
    var age: Int?
    var height: Double? // in cm
    var weight: Double? // in kg
    var habits: Habits
    var createdAt: Date
    var updatedAt: Date
    
    struct Habits: Codable {
        var smokingStatus: String? // "never", "former", "current"
        var alcoholConsumption: String? // "none", "light", "moderate", "heavy"
        var exerciseFrequency: String? // "none", "light", "moderate", "intense"
        var dietType: String? // "omnivore", "vegetarian", "vegan", etc.
        var sleepHours: Double?
        var stressLevel: Int? // 1-10 scale
        
        init(smokingStatus: String? = nil,
             alcoholConsumption: String? = nil,
             exerciseFrequency: String? = nil,
             dietType: String? = nil,
             sleepHours: Double? = nil,
             stressLevel: Int? = nil) {
            self.smokingStatus = smokingStatus
            self.alcoholConsumption = alcoholConsumption
            self.exerciseFrequency = exerciseFrequency
            self.dietType = dietType
            self.sleepHours = sleepHours
            self.stressLevel = stressLevel
        }
    }
    
    init(id: String,
         email: String,
         age: Int? = nil,
         height: Double? = nil,
         weight: Double? = nil,
         habits: Habits = Habits(),
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.email = email
        self.age = age
        self.height = height
        self.weight = weight
        self.habits = habits
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
