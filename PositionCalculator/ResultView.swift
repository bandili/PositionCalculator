//
//  ResultView.swift
//  PositionCalculator
//
//  Created by Bandi Li on 01.03.25.
//

import AppKit
import SwiftUI

struct ResultView: View {
    let result: PositionData
    @ObservedObject var vm: CalculatorViewModel
    @State private var showCopied = false
    @State private var showJSONCopied = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("建议开仓金额")
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
                ResultRow(title: "一倍止盈价", value: result.takeProfitPrice)
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
