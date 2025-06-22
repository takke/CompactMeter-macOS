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
        VStack(spacing: 24) {
            // アプリタイトル
            Text("CompactMeter")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // 全体のCPU使用率メーター
            VStack(spacing: 16) {
                Text("CPU使用率")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                CircularMeterView(
                    value: meterViewModel.animatedCPUUsage,
                    title: "全体",
                    color: .blue,
                    size: 120
                )
                
                // 詳細情報
                HStack(spacing: 20) {
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
            
            // コア別CPU使用率
            if let multiCoreData = meterViewModel.multiCoreCPUData {
                VStack(spacing: 16) {
                    Text("コア別使用率")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    MultiCoreView(
                        multiCoreData: multiCoreData,
                        size: 50,
                        showLabels: true
                    )
                }
            }
        }
        .padding(24)
        .frame(width: 520, height: 600)
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
