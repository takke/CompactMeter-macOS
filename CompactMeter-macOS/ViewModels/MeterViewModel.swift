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
        
        // CPU使用率の変化をアニメーション付きで反映（軽量化）
        $cpuUsage
            .map { $0.totalUsage }
            .removeDuplicates { abs($0 - $1) < 1.0 } // 1%未満の変化は無視
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main) // デバウンス追加
            .sink { [weak self] newUsage in
                withAnimation(.easeOut(duration: 0.5)) {
                    self?.animatedCPUUsage = newUsage
                }
            }
            .store(in: &cancellables)
        
        // マルチコアデータの変化をアニメーション付きで反映（軽量化）
        $multiCoreCPUData
            .compactMap { $0?.coreUsages.map { $0.totalUsage } }
            .removeDuplicates { old, new in
                // 配列の要素で1%以上の変化があった場合のみ更新
                guard old.count == new.count else { return false }
                return zip(old, new).allSatisfy { abs($0 - $1) < 1.0 }
            }
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] newUsages in
                withAnimation(.easeOut(duration: 0.5)) {
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
        
        // 最適化された単一API呼び出しで全体とコア別CPU使用率を同時に監視
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                Task {
                    // 単一API呼び出しで全体とコア別CPU使用率を同時に取得
                    if let cpuMonitor = (self.repository as? SystemMetricsRepository)?.cpuMonitor {
                        let multiCoreData = await cpuMonitor.getMultiCoreCPUUsageAsync()
                        
                        await MainActor.run {
                            self.cpuUsage = multiCoreData.total
                            if !multiCoreData.cores.isEmpty {
                                self.multiCoreCPUData = MultiCoreCPUData(totalUsage: multiCoreData.total, coreUsages: multiCoreData.cores)
                            }
                        }
                    } else {
                        // フォールバック処理
                        let totalUsage = await self.repository.getCPUUsageAsync()
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
