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
    private var appleSiliconCoreInfo: (pCores: Int, eCores: Int)?
    
    init() {
        // Apple SiliconのP/Eコア情報を初期化時に取得
        detectAppleSiliconCores()
    }
    
    /// sysctlからInteger値を取得するヘルパー関数
    private func getSysctlInt(_ name: String) -> Int? {
        var value: Int = 0
        var size = MemoryLayout<Int>.size
        let result = sysctlbyname(name, &value, &size, nil, 0)
        return result == 0 ? value : nil
    }
    
    /// Apple SiliconのP/Eコア情報を検出
    private func detectAppleSiliconCores() {
        // Pコア（Performance cores）
        let pCoresPhysical = getSysctlInt("hw.perflevel0.physicalcpu") ?? 0
        
        // Eコア（Efficiency cores）
        let eCoresPhysical = getSysctlInt("hw.perflevel1.physicalcpu") ?? 0
        
        // Apple Siliconでない場合（Intel Mac）は、perflevelパラメータが存在しない
        if pCoresPhysical > 0 || eCoresPhysical > 0 {
            appleSiliconCoreInfo = (pCores: pCoresPhysical, eCores: eCoresPhysical)
            print("Apple Silicon検出: Pコア=\(pCoresPhysical), Eコア=\(eCoresPhysical)")
        } else {
            appleSiliconCoreInfo = nil
            print("Intel Macまたはコア情報取得失敗")
        }
    }
    
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
    
    /// コア別CPU使用率を取得し、全体の使用率も同時に計算する（最適化版）
    func getMultiCoreCPUUsage() -> (total: CPUUsageData, cores: [CPUUsageData], coreInfos: [CPUCoreInfo]?) {
        var perCPUInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &perCPUInfo, &numCPUInfo)
        
        guard result == KERN_SUCCESS, let cpuInfo = perCPUInfo else {
            let defaultUsage = CPUUsageData(userUsage: 0, systemUsage: 0, idleUsage: 100)
            return (total: defaultUsage, cores: [], coreInfos: nil)
        }
        
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(Int(numCPUInfo) * MemoryLayout<integer_t>.size))
        }
        
        var cpuUsages: [CPUUsageData] = []
        var totalUserDiff: Double = 0
        var totalSystemDiff: Double = 0
        var totalIdleDiff: Double = 0
        var totalNiceDiff: Double = 0
        
        // previousPerCPUTicksのサイズを予め調整
        if previousPerCPUTicks.count != Int(numCPUs) {
            previousPerCPUTicks = Array(repeating: host_cpu_load_info(cpu_ticks: (0, 0, 0, 0)), count: Int(numCPUs))
        }
        
        for i in 0..<Int(numCPUs) {
            let cpuLoadInfoPtr = cpuInfo.advanced(by: i * Int(CPU_STATE_MAX))
            
            let userTicks = cpuLoadInfoPtr[Int(CPU_STATE_USER)]
            let systemTicks = cpuLoadInfoPtr[Int(CPU_STATE_SYSTEM)]
            let idleTicks = cpuLoadInfoPtr[Int(CPU_STATE_IDLE)]
            let niceTicks = cpuLoadInfoPtr[Int(CPU_STATE_NICE)]
            
            let currentCPUTicks = host_cpu_load_info(cpu_ticks: (natural_t(userTicks), natural_t(systemTicks), natural_t(idleTicks), natural_t(niceTicks)))
            
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
                
                // 全体の使用率計算のために累積
                totalUserDiff += userDiff
                totalSystemDiff += systemDiff
                totalIdleDiff += idleDiff
                totalNiceDiff += niceDiff
            } else {
                cpuUsages.append(CPUUsageData(userUsage: 0, systemUsage: 0, idleUsage: 100))
            }
            
            // 現在の値を保存
            previousPerCPUTicks[i] = currentCPUTicks
        }
        
        // 全体のCPU使用率を計算
        let totalAllDiff = totalUserDiff + totalSystemDiff + totalIdleDiff + totalNiceDiff
        let totalCPUUsage: CPUUsageData
        
        if totalAllDiff > 0 {
            let totalUserUsage = (totalUserDiff / totalAllDiff) * 100.0
            let totalSystemUsage = (totalSystemDiff / totalAllDiff) * 100.0
            let totalIdleUsage = (totalIdleDiff / totalAllDiff) * 100.0
            totalCPUUsage = CPUUsageData(userUsage: totalUserUsage, systemUsage: totalSystemUsage, idleUsage: totalIdleUsage)
        } else {
            totalCPUUsage = CPUUsageData(userUsage: 0, systemUsage: 0, idleUsage: 100)
        }
        
        // コアタイプ情報を構築
        var coreInfos: [CPUCoreInfo]? = nil
        if let siliconInfo = appleSiliconCoreInfo {
            coreInfos = []
            for (index, usage) in cpuUsages.enumerated() {
                let type: CPUCoreType
                if index < siliconInfo.pCores {
                    type = .performance
                } else if index < siliconInfo.pCores + siliconInfo.eCores {
                    type = .efficiency
                } else {
                    type = .unknown
                }
                coreInfos?.append(CPUCoreInfo(index: index, type: type, usage: usage))
            }
        }
        
        return (total: totalCPUUsage, cores: cpuUsages, coreInfos: coreInfos)
    }
    
    /// コア別CPU使用率を取得する（後方互換性のため維持）
    func getPerCPUUsage() -> [CPUUsageData] {
        let result = getMultiCoreCPUUsage()
        return result.cores
    }
    
    /// 非同期でマルチコアCPU使用率を取得する（最適化版）
    func getMultiCoreCPUUsageAsync() async -> (total: CPUUsageData, cores: [CPUUsageData], coreInfos: [CPUCoreInfo]?) {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let usage = self.getMultiCoreCPUUsage()
                continuation.resume(returning: usage)
            }
        }
    }
    
    /// 非同期でコア別CPU使用率を取得する（後方互換性のため維持）
    func getPerCPUUsageAsync() async -> [CPUUsageData] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let usage = self.getPerCPUUsage()
                continuation.resume(returning: usage)
            }
        }
    }
}