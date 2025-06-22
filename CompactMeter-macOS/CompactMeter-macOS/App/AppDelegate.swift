//
//  AppDelegate.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // デバッグ用：最初は通常のアプリとして起動（後でaccessoryに変更予定）
        NSApp.setActivationPolicy(.regular)
        
        // メニューバーマネージャーを初期化
        menuBarManager = MenuBarManager()
        
        print("CompactMeter アプリが開始されました")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // ウィンドウが閉じられてもアプリを終了しない
        return false
    }
}