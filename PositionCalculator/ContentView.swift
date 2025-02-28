//
//  ContentView.swift
//  PositionCalculator
//
//  Created by Bandi Li on 28.02.25.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - 应用委托

class AppDelegate: NSObject, NSApplicationDelegate {
    var popover: NSPopover!
    var statusItem: NSStatusItem!
    var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupApplication()
        setupStatusItem()
        setupPopover()
        setupEventMonitoring()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showPopover()
        }
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

// MARK: - 主视图

struct CalculatorView: View {
    @StateObject public var vm = CalculatorViewModel()
    @FocusState private var focusedField: FocusField?
    
    enum FocusField: Hashable {
        case entryPrice
        case stopLossPrice
        case stopLossAmount
        case feeRate
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HeaderView()
            
            VStack(spacing: 12) {
                // 开仓价格
                HStack {
                    Text("开仓价格")
                        .font(.subheadline)
                    Spacer()
                    TextField("", text: $vm.entryPrice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 180)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .entryPrice)
                        .onSubmit { vm.calculate() }
                }
                
                // 止损价格
                HStack {
                    Text("止损价格")
                        .font(.subheadline)
                    Spacer()
                    TextField("", text: $vm.stopLossPrice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 180)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .stopLossPrice)
                        .onSubmit { vm.calculate() }
                }
                
                // 亏损金额
                HStack {
                    Text("亏损金额")
                        .font(.subheadline)
                    Spacer()
                    TextField("", text: $vm.stopLossAmount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 180)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .stopLossAmount)
                        .onSubmit { vm.calculate() }
                }
                
                // 手续费率
                HStack {
                    Text("手续费率")
                        .font(.subheadline)
                    Spacer()
                    TextField("", text: $vm.feeRate)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 180)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .feeRate)
                        .onSubmit { vm.calculate() }
                }
            }
            
            // 使用占位符保留 ResultView 的位置
            if let result = vm.result {
                ResultView(result: result, vm: vm)
                    .transition(.opacity)
            } else {
                Color(.controlBackgroundColor)
                    .cornerRadius(8)
                    .frame(height: 100) // 设置与 ResultView 相同的高度
            }
            
            CalculateButton(vm: vm)
        }
        .padding()
        .frame(width: 280, height: 370)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .entryPrice
            }
        }
    }
}

// MARK: - HeaderView 添加设置按钮

struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)
            
            Text("仓位计算器")
                .font(.title3.bold())
        }
    }
}

// MARK: - 自定义组件

struct NumberField: NSViewRepresentable {
    let title: String
    @Binding var value: String
    
    private let formatter: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimum = 0
        fmt.maximumFractionDigits = 4
        return fmt
    }()
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = title
        textField.delegate = context.coordinator
        textField.font = .systemFont(ofSize: 14)
        textField.focusRingType = .none
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = value
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NumberField
        
        init(_ parent: NumberField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                let filtered = textField.stringValue.filter { "0123456789.".contains($0) }
                parent.value = filtered
            }
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                textView.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }
    }
}

struct CalculateButton: View {
    @ObservedObject var vm: CalculatorViewModel
    
    var body: some View {
        Button(action: vm.calculate) {
            HStack {
                Spacer()
                Text("立即计算")
                    .font(.headline)
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!vm.isValidInput)
    }
}

struct ResultView: View {
    let result: PositionData
    @ObservedObject var vm: CalculatorViewModel
    @State private var showCopied = false
    @State private var showJSONCopied = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("投资金额:")
                    .font(.subheadline)
                Spacer()
                HStack(spacing: 8) {
                    Text("\(result.investmentAmount, specifier: "%.2f")")
                        .font(.body.monospacedDigit())
                    
                    Button(action: copyToClipboard) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
                    
            VStack(alignment: .leading, spacing: 6) {
                ResultRow(title: "1倍止盈", value: result.takeProfitPrice)
                ResultRow(title: "手续费金额", value: result.investmentAmount * result.fee)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor))
        )
        .frame(height: 100) // 固定高度
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(String(format: "%.2f", result.investmentAmount), forType: .string)
        
        withAnimation {
            showCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showCopied = false
            }
        }
    }
}

struct ResultRow: View {
    let title: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: "%.2f", value))
                .font(.body.monospacedDigit())
        }
    }
}

// MARK: - 数据模型和ViewModel

struct PositionData: Codable, Equatable {
    let entryPrice: Double
    let stopLossPrice: Double
    let stopLossAmount: Double
    let investmentAmount: Double
    let takeProfitPrice: Double
    let fee: Double
}

class CalculatorViewModel: ObservableObject {
    @Published var entryPrice = ""
    @Published var stopLossPrice = ""
    @Published var stopLossAmount = "10"
    @Published var feeRate = "0.1"
    @Published var result: PositionData?
    
    var isValidInput: Bool {
        [entryPrice, stopLossPrice].allSatisfy { !$0.isEmpty } &&
            (Double(entryPrice) ?? 0) > 0 &&
            (Double(stopLossPrice) ?? 0) > 0
    }
    
    func calculate() {
        guard let entry = Double(entryPrice),
              let stopLoss = Double(stopLossPrice),
              let amount = Double(stopLossAmount),
              var fee = Double(feeRate),
              isValidInput else { return }
        
        fee /= 100
        let priceDiff = abs(entry - stopLoss)
        // 新的计算公式（包含手续费）
        let investment = (amount * entry) / (priceDiff + fee * entry)
            
        result = PositionData(
            entryPrice: entry,
            stopLossPrice: stopLoss,
            stopLossAmount: amount,
            investmentAmount: investment,
            takeProfitPrice: 2 * entry - stopLoss,
            fee: fee
        )
    }
}

// 新增按钮样式
struct LinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
            .underline()
            .padding(4)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
