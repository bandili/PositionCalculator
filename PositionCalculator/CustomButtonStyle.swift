//
//  Styles.swift
//  PositionCalculator
//
//  Created by Bandi Li on 01.03.25.
//

import AppKit
import SwiftUI


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
