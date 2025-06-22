//
//  MenuBarManager.swift
//  CompactMeter-macOS
//
//  Created by Hiroaki Takeuchi on 2025/06/23.
//

import Cocoa
import SwiftUI

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    init() {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        // ステータスアイテムを作成
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // アイコンとボタンを設定
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "CPU Monitor")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // ポップオーバーを設定
        setupPopover()
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 200)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarPopoverView())
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}