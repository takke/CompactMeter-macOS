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
    let perCPUUsage: [CPUUsageData]
    let timestamp: Date
    
    init(cpuUsage: CPUUsageData, perCPUUsage: [CPUUsageData] = []) {
        self.cpuUsage = cpuUsage
        self.perCPUUsage = perCPUUsage
        self.timestamp = Date()
    }
}

struct MultiCoreCPUData {
    let totalUsage: CPUUsageData
    let coreUsages: [CPUUsageData]
    let coreCount: Int
    let timestamp: Date
    
    init(totalUsage: CPUUsageData, coreUsages: [CPUUsageData]) {
        self.totalUsage = totalUsage
        self.coreUsages = coreUsages
        self.coreCount = coreUsages.count
        self.timestamp = Date()
    }
    
    // コア別の平均使用率を計算
    var averageCoreUsage: Double {
        guard !coreUsages.isEmpty else { return 0 }
        let total = coreUsages.reduce(0) { $0 + $1.totalUsage }
        return total / Double(coreUsages.count)
    }
    
    // 最も使用率の高いコアを取得
    var maxCoreUsage: (index: Int, usage: Double)? {
        guard !coreUsages.isEmpty else { return nil }
        let maxIndex = coreUsages.enumerated().max { $0.element.totalUsage < $1.element.totalUsage }?.offset ?? 0
        return (index: maxIndex, usage: coreUsages[maxIndex].totalUsage)
    }
    
    // 最も使用率の低いコアを取得
    var minCoreUsage: (index: Int, usage: Double)? {
        guard !coreUsages.isEmpty else { return nil }
        let minIndex = coreUsages.enumerated().min { $0.element.totalUsage < $1.element.totalUsage }?.offset ?? 0
        return (index: minIndex, usage: coreUsages[minIndex].totalUsage)
    }
}