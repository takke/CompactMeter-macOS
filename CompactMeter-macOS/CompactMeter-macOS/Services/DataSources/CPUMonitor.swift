//
//  CPUMonitor.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import Foundation
import Darwin

class CPUMonitor: ObservableObject {
    private var previousCPUTicks: host_cpu_load_info?
    
    /// CPU使用率を取得する
    func getCPUUsage() -> CPUUsageData {
        var size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        defer { hostInfo.deallocate() }
        
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
        }
        
        guard result == KERN_SUCCESS else {
            return CPUUsageData(userUsage: 0, systemUsage: 0, idleUsage: 100)
        }
        
        let loadInfo = hostInfo.pointee
        let currentTicks = loadInfo
        
        // 前回の値と比較して使用率を計算
        if let previousTicks = previousCPUTicks {
            let userDiff = Double(currentTicks.cpu_ticks.0 - previousTicks.cpu_ticks.0)
            let systemDiff = Double(currentTicks.cpu_ticks.1 - previousTicks.cpu_ticks.1)
            let idleDiff = Double(currentTicks.cpu_ticks.2 - previousTicks.cpu_ticks.2)
            let niceDiff = Double(currentTicks.cpu_ticks.3 - previousTicks.cpu_ticks.3)
            
            let totalDiff = userDiff + systemDiff + idleDiff + niceDiff
            
            if totalDiff > 0 {
                let userUsage = (userDiff / totalDiff) * 100.0
                let systemUsage = (systemDiff / totalDiff) * 100.0
                let idleUsage = (idleDiff / totalDiff) * 100.0
                
                previousCPUTicks = currentTicks
                return CPUUsageData(userUsage: userUsage, systemUsage: systemUsage, idleUsage: idleUsage)
            }
        }
        
        // 初回実行時は前回値として保存
        previousCPUTicks = currentTicks
        return CPUUsageData(userUsage: 0, systemUsage: 0, idleUsage: 100)
    }
    
    /// 非同期でCPU使用率を取得する
    func getCPUUsageAsync() async -> CPUUsageData {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let usage = self.getCPUUsage()
                continuation.resume(returning: usage)
            }
        }
    }
}