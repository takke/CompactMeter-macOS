//
//  SystemMetricsRepository.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import Foundation
import Combine

protocol SystemMetricsRepositoryProtocol {
    func getCPUUsage() -> CPUUsageData
    func getCPUUsageAsync() async -> CPUUsageData
    func startCPUUsageMonitoring(interval: TimeInterval) -> AnyPublisher<CPUUsageData, Never>
    func stopCPUUsageMonitoring()
}

class SystemMetricsRepository: ObservableObject, SystemMetricsRepositoryProtocol {
    let cpuMonitor = CPUMonitor() // publicアクセス用にletで公開
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    
    private let cpuUsageSubject = PassthroughSubject<CPUUsageData, Never>()
    
    func getCPUUsage() -> CPUUsageData {
        return cpuMonitor.getCPUUsage()
    }
    
    func getCPUUsageAsync() async -> CPUUsageData {
        return await cpuMonitor.getCPUUsageAsync()
    }
    
    func startCPUUsageMonitoring(interval: TimeInterval = 1.0) -> AnyPublisher<CPUUsageData, Never> {
        stopCPUUsageMonitoring()
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let usage = self.cpuMonitor.getCPUUsage()
            self.cpuUsageSubject.send(usage)
        }
        
        return cpuUsageSubject.eraseToAnyPublisher()
    }
    
    func stopCPUUsageMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    deinit {
        stopCPUUsageMonitoring()
    }
}