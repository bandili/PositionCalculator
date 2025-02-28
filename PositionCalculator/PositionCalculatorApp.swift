//
//  PositionCalculatorApp.swift
//  PositionCalculator
//
//  Created by Bandi Li on 28.02.25.
//

import SwiftUI

@main
struct PositionCalculatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
