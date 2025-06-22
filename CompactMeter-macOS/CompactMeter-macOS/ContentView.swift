//
//  ContentView.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var meterViewModel = MeterViewModel()
    
    var body: some View {
        VStack(spacing: 12) {
            Text("CPU使用率")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // 全体のメーターとコア別メーターを横並びに配置
            HStack(alignment: .top, spacing: 20) {
                // 左側：全体のCPU使用率メーター
                VStack(spacing: 12) {
                    CircularMeterView(
                        value: meterViewModel.animatedCPUUsage,
                        title: "全体",
                        color: .blue,
                        size: 120
                    )
                    
                    // 詳細情報
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            VStack {
                                Text("User")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f%%", meterViewModel.cpuUsage.userUsage))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack {
                                Text("System")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f%%", meterViewModel.cpuUsage.systemUsage))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.orange)
                            }
                            
                            VStack {
                                Text("Idle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f%%", meterViewModel.cpuUsage.idleUsage))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .frame(minWidth: 200)
                
                // 右側：コア別CPU使用率
                if let multiCoreData = meterViewModel.multiCoreCPUData {
                    VStack(spacing: 12) {
                        MultiCoreView(
                            multiCoreData: multiCoreData,
                            size: 45,
                            showLabels: true
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .frame(minWidth: 600, minHeight: 300)
        .onAppear {
            meterViewModel.startMultiCoreMonitoring(interval: 1.0)
        }
        .onDisappear {
            meterViewModel.stopMonitoring()
        }
    }
}

#Preview {
    ContentView()
}
