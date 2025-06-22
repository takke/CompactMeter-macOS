//
//  MultiCoreView.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import SwiftUI

struct MultiCoreView: View {
    let multiCoreData: MultiCoreCPUData
    let size: CGFloat
    let showLabels: Bool
    
    init(multiCoreData: MultiCoreCPUData, size: CGFloat = 60, showLabels: Bool = true) {
        self.multiCoreData = multiCoreData
        self.size = size
        self.showLabels = showLabels
    }
    
    private let maxCoresPerRow = 5
    
    var body: some View {
        VStack(spacing: 8) {
            // 全体の使用率表示
            HStack {
                Text("全体")
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Text(String(format: "%.1f%%", multiCoreData.totalUsage.totalUsage))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.blue)
            }
            
            // コア別メーター表示
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(multiCoreData.coreCount, maxCoresPerRow)), spacing: 12) {
                ForEach(Array(multiCoreData.coreUsages.enumerated()), id: \.offset) { index, coreUsage in
                    VStack(spacing: 6) {
                        CircularMeterView(
                            value: coreUsage.totalUsage,
                            title: "",
                            color: colorForCore(index: index, usage: coreUsage.totalUsage),
                            size: size
                        )
                        
                        if showLabels {
                            VStack(spacing: 2) {
                                Text("コア\(index)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(String(format: "%.0f%%", coreUsage.totalUsage))
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            
            // 統計情報
            if showLabels {
                VStack(spacing: 6) {
                    HStack {
                        Text("平均")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f%%", multiCoreData.averageCoreUsage))
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if let maxCore = multiCoreData.maxCoreUsage {
                        HStack {
                            Text("最大")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("コア\(maxCore.index): \(String(format: "%.1f%%", maxCore.usage))")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.red)
                        }
                    }
                    
                    if let minCore = multiCoreData.minCoreUsage {
                        HStack {
                            Text("最小")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("コア\(minCore.index): \(String(format: "%.1f%%", minCore.usage))")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    // コアの使用率に応じて色を決定
    private func colorForCore(index: Int, usage: Double) -> Color {
        if usage > 80 {
            return .red
        } else if usage > 60 {
            return .orange
        } else if usage > 40 {
            return .yellow
        } else {
            return .blue
        }
    }
}

struct MultiCoreView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCoreUsages = [
            CPUUsageData(userUsage: 15.0, systemUsage: 10.0, idleUsage: 75.0),
            CPUUsageData(userUsage: 30.0, systemUsage: 20.0, idleUsage: 50.0),
            CPUUsageData(userUsage: 5.0, systemUsage: 5.0, idleUsage: 90.0),
            CPUUsageData(userUsage: 70.0, systemUsage: 15.0, idleUsage: 15.0),
            CPUUsageData(userUsage: 20.0, systemUsage: 25.0, idleUsage: 55.0),
            CPUUsageData(userUsage: 40.0, systemUsage: 10.0, idleUsage: 50.0),
            CPUUsageData(userUsage: 60.0, systemUsage: 30.0, idleUsage: 10.0),
            CPUUsageData(userUsage: 10.0, systemUsage: 15.0, idleUsage: 75.0)
        ]
        
        let totalUsage = CPUUsageData(userUsage: 31.25, systemUsage: 16.25, idleUsage: 52.5)
        let multiCoreData = MultiCoreCPUData(totalUsage: totalUsage, coreUsages: sampleCoreUsages)
        
        VStack(spacing: 20) {
            MultiCoreView(multiCoreData: multiCoreData, size: 50)
            
            MultiCoreView(multiCoreData: multiCoreData, size: 40, showLabels: false)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}