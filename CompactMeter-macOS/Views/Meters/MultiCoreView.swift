//
//  MultiCoreView.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import SwiftUI

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct MultiCoreView: View {
    let multiCoreData: MultiCoreCPUData
    let animatedCoreUsages: [Double]?
    let size: CGFloat
    let showLabels: Bool
    
    init(multiCoreData: MultiCoreCPUData, animatedCoreUsages: [Double]? = nil, size: CGFloat = 60, showLabels: Bool = true) {
        self.multiCoreData = multiCoreData
        self.animatedCoreUsages = animatedCoreUsages
        self.size = size
        self.showLabels = showLabels
    }
    
    private let maxCoresPerRow = 5
    
    var body: some View {
        VStack(spacing: 8) {
            // コア別メーター表示
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(multiCoreData.coreCount, maxCoresPerRow)), spacing: 12) {
                ForEach(Array(multiCoreData.coreUsages.enumerated()), id: \.offset) { index, coreUsage in
                    VStack(spacing: 5) {
                        CircularMeterView(
                            value: animatedCoreUsages?[safe: index] ?? coreUsage.totalUsage,
                            color: colorForCore(index: index, usage: animatedCoreUsages?[safe: index] ?? coreUsage.totalUsage),
                            size: size
                        )
                        
                        if showLabels {
                            Text("コア\(index)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
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
