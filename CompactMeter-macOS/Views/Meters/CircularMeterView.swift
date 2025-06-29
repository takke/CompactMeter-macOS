//
//  CircularMeterView.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import SwiftUI

struct CircularMeterView: View {
    let value: Double // 0-100の値
    let color: Color
    let size: CGFloat
    let borderColor: Color? // 枠線の色（nilの場合は枠線なし）
    
    init(value: Double, color: Color = .blue, size: CGFloat = 80, borderColor: Color? = nil) {
        self.value = max(0, min(100, value)) // 0-100の範囲に制限
        self.color = color
        self.size = size
        self.borderColor = borderColor
    }
    
    private var progress: Double {
        value / 100.0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: size, height: size)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: 8,
                            lineCap: .round
                        )
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90)) // 12時方向から開始
                
                // Center text
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", value))
                        .font(.system(size: size * 0.25, weight: .bold, design: .monospaced))
                        .foregroundColor(color)
                    
                    Text("%")
                        .font(.system(size: size * 0.15, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            // コアタイプ判別用の枠線
            .overlay(
                borderColor != nil ?
                Circle()
                    .stroke(borderColor!, lineWidth: 1)
                    .frame(width: size + 10, height: size + 10)
                : nil
            )
        }
    }
}

struct CircularMeterView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            CircularMeterView(value: 25, color: .blue)
            CircularMeterView(value: 65, color: .green)
            CircularMeterView(value: 90, color: .red)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
