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
        
        print("CompactMeter アプリが開始されました")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // ウィンドウが閉じられたらアプリを終了
        return true
    }
}
