//
//  CalculatorView.swift
//  PositionCalculator
//
//  Created by Bandi Li on 01.03.25.
//
import AppKit
import SwiftUI

class CalculatorViewModel: ObservableObject {
    static let shared = CalculatorViewModel()
    
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

// MARK: - 数据模型和ViewModel

struct PositionData: Codable, Equatable {
    let entryPrice: Double
    let stopLossPrice: Double
    let stopLossAmount: Double
    let investmentAmount: Double
    let takeProfitPrice: Double
    let fee: Double
}

// MARK: - 主视图

struct CalculatorView: View {
    @StateObject public var vm = CalculatorViewModel.shared
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
        .frame(width: 280, height: 300)
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

