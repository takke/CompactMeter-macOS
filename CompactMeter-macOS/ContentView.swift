//
//  ContentView.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var meterViewModel = MeterViewModel()
    
    var body: some View {
        VStack(spacing: 12) {
//            Text("CPU使用率")
//                .font(.headline)
//                .foregroundColor(.secondary)
            
            // 全体のメーターとコア別メーターを横並びに配置
            HStack(alignment: .top, spacing: 20) {
                // 左側：全体のCPU使用率メーター
                VStack(spacing: 12) {
                    CircularMeterView(
                        value: meterViewModel.animatedCPUUsage,
                        color: colorForCPUUsage(meterViewModel.animatedCPUUsage),
                        size: 80
                    )
                    
                    // 詳細情報
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            VStack {
                                Text("User")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f%%", meterViewModel.cpuUsage.userUsage))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.blue)
                                    .frame(minWidth: 35)
                            }
                            .frame(width: 40)
                            
                            VStack {
                                Text("System")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f%%", meterViewModel.cpuUsage.systemUsage))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.orange)
                                    .frame(minWidth: 35)
                            }
                            .frame(width: 40)
                            
                            VStack {
                                Text("Idle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f%%", meterViewModel.cpuUsage.idleUsage))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.green)
                                    .frame(minWidth: 35)
                            }
                            .frame(width: 40)
                        }
                    }
                }
                .frame(minWidth: 100)
                
                // 右側：コア別CPU使用率
                if let multiCoreData = meterViewModel.multiCoreCPUData {
                    VStack(spacing: 20) {
                        MultiCoreView(
                            multiCoreData: multiCoreData,
                            animatedCoreUsages: meterViewModel.animatedCoreUsages,
                            size: 45,
                            showLabels: false
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(4)
        .frame(minWidth: 400, minHeight: 140)
        .background(DraggableWindowBackground())
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            meterViewModel.startMultiCoreMonitoring(interval: 2.0)
        }
        .onDisappear {
            meterViewModel.stopMonitoring()
        }
    }
    
    // CPU使用率に応じて色を決定
    private func colorForCPUUsage(_ usage: Double) -> Color {
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

struct DraggableWindowBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DraggableView()
        view.coordinator = context.coordinator
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class DraggableView: NSView {
        var coordinator: Coordinator?
        
        override func mouseDown(with event: NSEvent) {
            coordinator?.mouseDown(with: event, in: self)
        }
        
        override func mouseDragged(with event: NSEvent) {
            coordinator?.mouseDragged(with: event, in: self)
        }
    }
    
    class Coordinator: NSObject {
        private var initialLocation: NSPoint = .zero
        
        func mouseDown(with event: NSEvent, in view: NSView) {
            guard let window = view.window else { return }
            initialLocation = event.locationInWindow
        }
        
        func mouseDragged(with event: NSEvent, in view: NSView) {
            guard let window = view.window else { return }
            
            let currentLocation = event.locationInWindow
            let deltaX = currentLocation.x - initialLocation.x
            let deltaY = currentLocation.y - initialLocation.y
            
            let currentFrame = window.frame
            let newOrigin = NSPoint(
                x: currentFrame.origin.x + deltaX,
                y: currentFrame.origin.y + deltaY
            )
            
            window.setFrameOrigin(newOrigin)
        }
    }
}

#Preview {
    ContentView()
}
