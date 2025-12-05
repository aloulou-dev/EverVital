//
//  LifeExpectancy.swift
//  EverVital
//
//  Created by Malek Aloulou on 12/2/25.
//

import Foundation

struct LifeExpectancyResult: Identifiable, Codable {
    let id: String
    let userId: String
    var lifeExpectancy: Double // in years
    var insightsSummary: String
    var calculatedAt: Date
    
    init(id: String = UUID().uuidString,
         userId: String,
         lifeExpectancy: Double,
         insightsSummary: String,
         calculatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.lifeExpectancy = lifeExpectancy
        self.insightsSummary = insightsSummary
        self.calculatedAt = calculatedAt
    }
}
