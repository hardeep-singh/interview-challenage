//
//  ContentView.swift
//  Levno-4Aug
//
//  Created by Hardeep Singh on 04/08/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        WaterUsageView(viewModel: WaterUsageViewModel(waterUsageUseCase: WaterUsageUseCaseImp()))
    }
}

#Preview {
    ContentView()
}
