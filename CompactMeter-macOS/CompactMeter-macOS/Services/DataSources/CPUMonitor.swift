//
//  CPUMonitor.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import Foundation
import Darwin

class CPUMonitor: ObservableObject, @unchecked Sendable {
    private var previousCPUTicks: host_cpu_load_info?
    private var previousPerCPUTicks: [host_cpu_load_info] = []
    
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
    
    /// コア別CPU使用率を取得する
    func getPerCPUUsage() -> [CPUUsageData] {
        var perCPUInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &perCPUInfo, &numCPUInfo)
        
        guard result == KERN_SUCCESS, let cpuInfo = perCPUInfo else {
            return []
        }
        
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(Int(numCPUInfo) * MemoryLayout<integer_t>.size))
        }
        
        var cpuUsages: [CPUUsageData] = []
        
        for i in 0..<Int(numCPUs) {
            let cpuLoadInfoPtr = cpuInfo.advanced(by: i * Int(CPU_STATE_MAX))
            
            let userTicks = cpuLoadInfoPtr[Int(CPU_STATE_USER)]
            let systemTicks = cpuLoadInfoPtr[Int(CPU_STATE_SYSTEM)]
            let idleTicks = cpuLoadInfoPtr[Int(CPU_STATE_IDLE)]
            let niceTicks = cpuLoadInfoPtr[Int(CPU_STATE_NICE)]
            
            let currentCPUTicks = host_cpu_load_info(cpu_ticks: (natural_t(userTicks), natural_t(systemTicks), natural_t(idleTicks), natural_t(niceTicks)))
            
            // 前回の値と比較して使用率を計算
            if i < previousPerCPUTicks.count {
                let previousTicks = previousPerCPUTicks[i]
                
                let userDiff = Double(currentCPUTicks.cpu_ticks.0 - previousTicks.cpu_ticks.0)
                let systemDiff = Double(currentCPUTicks.cpu_ticks.1 - previousTicks.cpu_ticks.1)
                let idleDiff = Double(currentCPUTicks.cpu_ticks.2 - previousTicks.cpu_ticks.2)
                let niceDiff = Double(currentCPUTicks.cpu_ticks.3 - previousTicks.cpu_ticks.3)
                
                let totalDiff = userDiff + systemDiff + idleDiff + niceDiff
                
                if totalDiff > 0 {
                    let userUsage = (userDiff / totalDiff) * 100.0
                    let systemUsage = (systemDiff / totalDiff) * 100.0
                    let idleUsage = (idleDiff / totalDiff) * 100.0
                    
                    cpuUsages.append(CPUUsageData(userUsage: userUsage, systemUsage: systemUsage, idleUsage: idleUsage))
                } else {
                    cpuUsages.append(CPUUsageData(userUsage: 0, systemUsage: 0, idleUsage: 100))
                }
            } else {
                // 初回実行時
                cpuUsages.append(CPUUsageData(userUsage: 0, systemUsage: 0, idleUsage: 100))
            }
            
            // 現在の値を保存（配列のサイズを調整）
            if i < previousPerCPUTicks.count {
                previousPerCPUTicks[i] = currentCPUTicks
            } else {
                previousPerCPUTicks.append(currentCPUTicks)
            }
        }
        
        return cpuUsages
    }
    
    /// 非同期でコア別CPU使用率を取得する
    func getPerCPUUsageAsync() async -> [CPUUsageData] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let usage = self.getPerCPUUsage()
                continuation.resume(returning: usage)
            }
        }
    }
}