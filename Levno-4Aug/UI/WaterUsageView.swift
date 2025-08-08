//
//  WaterUsageView.swift
//  Levno-4Aug
//
//  Created by Hardeep Singh on 04/08/2025.
//

import SwiftUI

struct WaterUsageView: View {
    @ObservedObject var viewModel: WaterUsageViewModel
    init(viewModel: WaterUsageViewModel) {
        self.viewModel = viewModel
    }
    var body: some View {
        List(viewModel.list) { date in
            WaterUsageRowView(usage: date)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .onAppear {
            viewModel.fetchRequest()
        }
    }
}

#Preview {
    WaterUsageView(
        viewModel: WaterUsageViewModel(waterUsageUseCase: WaterUsageUseCaseImp())
    )
}

struct WaterUsageRowView: View {
    let usage: UIOWaterUsage
    
    var body: some View {
        VStack(spacing: 0) {
            
            if !usage.overNightLeak {
                HStack {
                    Text("Possible leak detected on this day")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: 30)
                .background(Color.red.opacity(0.8))
            }
            
            Text(usage.date)
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(Color.blue.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            VStack(spacing: 5) {
                HStack(alignment: .top) {
                    Text("Daily Usage:")
                        .font(.title)
                        .fontWeight(.regular)
                        .foregroundColor(Color.black.opacity(0.8))                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(usage.dailyUsage)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.black.opacity(0.8))
                        .frame(alignment: .leading)
                }
                
                HStack(alignment: .top) {
                    Text("Overnight Usage:")
                        .font(.title)
                        .fontWeight(.regular)
                        .foregroundColor(Color.black.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(usage.overnightUsages)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.black.opacity(0.8))
                        .frame( alignment: .leading)
                }
            }
            .padding(16)
        }
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}
