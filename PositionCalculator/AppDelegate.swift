//
//  ContentView.swift
//  PositionCalculator
//
//  Created by Bandi Li on 28.02.25.
//

import AppKit
import CoreServices
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

// MARK: - 应用委托

class AppDelegate: NSObject, NSApplicationDelegate {
    var popover: NSPopover!
    var statusItem: NSStatusItem!
    var eventMonitor: EventMonitor?
    var settingsWindow: NSWindow?
    @ObservedObject var settingsViewModel = SettingsViewModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupApplication()
        setupStatusItem()
        setupPopover()
        setupEventMonitoring()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showPopover()
        }
        
        // 检查是否设置为登录启动
        settingsViewModel.checkLoginItemStatus()
    }
    
    private func setupApplication() {
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis", accessibilityDescription: "Position Calculator")
            button.action = #selector(handleStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            // 右键点击，显示菜单
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "设置", action: #selector(showSettings), keyEquivalent: ","))
            menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem?.popUpMenu(menu)
        } else {
            // 左键点击，切换弹出窗口
            togglePopover(sender)
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 380)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: CalculatorView())
    }
    
    @objc func showSettings() {
        if let window = settingsWindow {
            // 如果窗口已存在，确保它显示在屏幕中央
            centerWindow(window)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
    
        // 创建设置窗口
        let settingsView = SettingsView(viewModel: settingsViewModel)
        let hostingController = NSHostingController(rootView: settingsView)
    
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 250),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
    
        // 设置窗口标题
        window.title = "设置"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
    
        // 确保窗口的尺寸和位置已经准备好
        window.setFrameAutosaveName("SettingsWindow") // 可选：保存窗口位置
        window.setContentSize(NSSize(width: 320, height: 250)) // 显式设置窗口尺寸
    
        // 将窗口居中
        centerWindow(window)
    
        // 显示窗口
        window.makeKeyAndOrderFront(nil)
    
        // 保存窗口引用
        settingsWindow = window
    
        // 激活应用
        NSApp.activate(ignoringOtherApps: true)
    }

    /// 将窗口居中显示
    private func centerWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
    
        // 获取屏幕的可见区域
        let screenRect = screen.visibleFrame
    
        // 获取窗口的尺寸
        let windowRect = window.frame
    
        // 计算窗口的中心点坐标
        let x = screenRect.midX - (windowRect.width / 2)
        let y = screenRect.midY - (windowRect.height / 2)
    
        // 设置窗口的位置
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    private func setupEventMonitoring() {
        eventMonitor = EventMonitor(mask: [.keyDown, .leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            
            if let keyEvent = event as? NSEvent, keyEvent.type == .keyDown {
                if keyEvent.keyCode == 53 { // ESC键
                    self.closePopover()
                }
            } else if self.popover.isShown {
                self.closePopover()
            }
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        eventMonitor?.start()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    private func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()
    }
    
    // 处理应用图标的点击事件
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !popover.isShown {
            showPopover()
        }
        return true
    }
}

// MARK: - 事件监听器

class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
