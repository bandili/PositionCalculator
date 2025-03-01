//
//  Styles.swift
//  PositionCalculator
//
//  Created by Bandi Li on 01.03.25.
//


import AppKit
import SwiftUI


// MARK: - 设置视图

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 15) {
                HStack {
                    Text("默认亏损金额")
                    Spacer()
                    TextField("", text: $viewModel.defaultStopLossAmount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: viewModel.defaultStopLossAmount) { _ in
                            viewModel.updateDefaultValues()
                        }
                }
                
                HStack {
                    Text("默认手续费率")
                    Spacer()
                    TextField("", text: $viewModel.defaultFeeRate)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: viewModel.defaultFeeRate) { _ in
                            viewModel.updateDefaultValues()
                        }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: 260, height: 80)
        .padding()
    }
}

// MARK: - 设置视图模型

class SettingsViewModel: ObservableObject {
    @Published var launchAtLogin: Bool = false
    @Published var defaultStopLossAmount: String = "10"
    @Published var defaultFeeRate: String = "0.1"
    
    private let calculatorVM = CalculatorViewModel.shared
    private let defaults = UserDefaults.standard
    private let launchAtLoginKey = "launchAtLoginEnabled"
    
    init() {
        defaultStopLossAmount = calculatorVM.stopLossAmount
        defaultFeeRate = calculatorVM.feeRate
        checkLoginItemStatus()
    }
    
    func checkLoginItemStatus() {
        // 从 UserDefaults 读取设置
        launchAtLogin = defaults.bool(forKey: launchAtLoginKey)
    }
    
    func updateDefaultValues() {
        calculatorVM.stopLossAmount = defaultStopLossAmount
        calculatorVM.feeRate = defaultFeeRate
    }
}
