//
//  MetricData.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import Foundation

struct CPUUsageData {
    let userUsage: Double
    let systemUsage: Double
    let idleUsage: Double
    
    var totalUsage: Double {
        return userUsage + systemUsage
    }
    
    var timestamp: Date
    
    init(userUsage: Double, systemUsage: Double, idleUsage: Double) {
        self.userUsage = userUsage
        self.systemUsage = systemUsage
        self.idleUsage = idleUsage
        self.timestamp = Date()
    }
}

struct SystemMetrics {
    let cpuUsage: CPUUsageData
    let timestamp: Date
    
    init(cpuUsage: CPUUsageData) {
        self.cpuUsage = cpuUsage
        self.timestamp = Date()
    }
}