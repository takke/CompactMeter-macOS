//
//  MenuBarPopoverView.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import SwiftUI

struct MenuBarPopoverView: View {
    @StateObject private var meterViewModel = MeterViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.blue)
                Text("CompactMeter")
                    .font(.headline)
                Spacer()
                
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            // 全体のCPU表示
            VStack(spacing: 12) {
                CircularMeterView(
                    value: meterViewModel.animatedCPUUsage,
                    title: "CPU",
                    color: .blue,
                    size: 80
                )
                
                // 詳細情報
                VStack(spacing: 4) {
                    Text(meterViewModel.formattedCPUUsage)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        Text(meterViewModel.formattedUserUsage)
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text(meterViewModel.formattedSystemUsage)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // コア別CPU表示（常に表示）
            if let multiCoreData = meterViewModel.multiCoreCPUData {
                Divider()
                
                ScrollView {
                    MultiCoreView(
                        multiCoreData: multiCoreData,
                        size: 32,
                        showLabels: true
                    )
                }
                .frame(maxHeight: 350)
            }
            
            // フッター
            HStack {
                Button(meterViewModel.isMonitoring ? "停止" : "開始") {
                    if meterViewModel.isMonitoring {
                        meterViewModel.stopMonitoring()
                    } else {
                        meterViewModel.startMonitoring()
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("設定") {
                    // TODO: 設定画面を開く
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 520, height: 570)
        .onAppear {
            meterViewModel.startMultiCoreMonitoring()
        }
        .onDisappear {
            meterViewModel.stopMonitoring()
        }
    }
}

#Preview {
    MenuBarPopoverView()
}
