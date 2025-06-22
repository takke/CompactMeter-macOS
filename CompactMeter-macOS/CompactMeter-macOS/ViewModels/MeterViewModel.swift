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
    @Published var multiCoreCPUData: MultiCoreCPUData?
    @Published var isMonitoring: Bool = false
    
    private let repository: SystemMetricsRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // アニメーション用の値
    @Published var animatedCPUUsage: Double = 0
    @Published var animatedCoreUsages: [Double] = []
    
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
        
        // マルチコアデータの変化をアニメーション付きで反映
        $multiCoreCPUData
            .compactMap { $0?.coreUsages.map { $0.totalUsage } }
            .removeDuplicates()
            .sink { [weak self] newUsages in
                withAnimation(.easeInOut(duration: 0.5)) {
                    self?.animatedCoreUsages = newUsages
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
    
    func startMultiCoreMonitoring(interval: TimeInterval = 1.0) {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // 全体のCPU使用率とコア別CPU使用率を同時に監視
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                Task {
                    // 全体のCPU使用率を取得
                    let totalUsage = await self.repository.getCPUUsageAsync()
                    
                    // コア別CPU使用率を取得
                    if let cpuMonitor = (self.repository as? SystemMetricsRepository)?.cpuMonitor {
                        let perCoreUsages = await cpuMonitor.getPerCPUUsageAsync()
                        
                        await MainActor.run {
                            self.cpuUsage = totalUsage
                            if !perCoreUsages.isEmpty {
                                self.multiCoreCPUData = MultiCoreCPUData(totalUsage: totalUsage, coreUsages: perCoreUsages)
                            }
                        }
                    } else {
                        await MainActor.run {
                            self.cpuUsage = totalUsage
                        }
                    }
                }
            }
            .store(in: &cancellables)
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