//
//  MeterViewModel.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import Foundation
import Combine
import SwiftUI

class MeterViewModel: ObservableObject {
    @Published var cpuUsage: CPUUsageData = CPUUsageData(userUsage: 0, systemUsage: 0, idleUsage: 100)
    @Published var isMonitoring: Bool = false
    
    private let repository: SystemMetricsRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // アニメーション用の値
    @Published var animatedCPUUsage: Double = 0
    
    init(repository: SystemMetricsRepositoryProtocol = SystemMetricsRepository()) {
        self.repository = repository
        
        // CPU使用率の変化をアニメーション付きで反映
        $cpuUsage
            .map { $0.totalUsage }
            .removeDuplicates()
            .sink { [weak self] newUsage in
                withAnimation(.easeInOut(duration: 0.5)) {
                    self?.animatedCPUUsage = newUsage
                }
            }
            .store(in: &cancellables)
    }
    
    func startMonitoring(interval: TimeInterval = 1.0) {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        repository.startCPUUsageMonitoring(interval: interval)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cpuData in
                self?.cpuUsage = cpuData
            }
            .store(in: &cancellables)
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        repository.stopCPUUsageMonitoring()
        isMonitoring = false
        
        cancellables.removeAll()
    }
    
    func refreshCPUUsage() async {
        let usage = await repository.getCPUUsageAsync()
        await MainActor.run {
            self.cpuUsage = usage
        }
    }
    
    // フォーマット用のメソッド
    var formattedCPUUsage: String {
        return String(format: "%.1f%%", cpuUsage.totalUsage)
    }
    
    var formattedUserUsage: String {
        return String(format: "User: %.1f%%", cpuUsage.userUsage)
    }
    
    var formattedSystemUsage: String {
        return String(format: "System: %.1f%%", cpuUsage.systemUsage)
    }
    
    deinit {
        stopMonitoring()
    }
}