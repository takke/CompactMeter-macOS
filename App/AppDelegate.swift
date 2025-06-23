//
//  AppDelegate.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 通常のウィンドウアプリとして起動
        NSApp.setActivationPolicy(.regular)
        
        // 全てのウィンドウのタイトルバーを完全に削除
        DispatchQueue.main.async {
            for window in NSApp.windows {
                self.configureWindow(window)
            }
        }
        
        print("CompactMeter アプリが開始されました")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // ウィンドウが閉じられたらアプリを終了
        return true
    }
    
    private func configureWindow(_ window: NSWindow) {
        // タイトルバーを完全に非表示
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        
        // ウィンドウの外観設定
        window.hasShadow = true
        window.isOpaque = true
        window.backgroundColor = NSColor.controlBackgroundColor
        
        // 最小サイズを更新（タイトルバーがないので、より小さく設定可能）
        window.minSize = NSSize(width: 500, height: 140)
        
        // ウィンドウを前面に表示
        window.level = .normal
    }
}
