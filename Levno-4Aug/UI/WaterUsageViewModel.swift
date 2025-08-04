//
//  WaterUsageViewModel.swift
//  Levno-4Aug
//
//  Created by Hardeep Singh on 04/08/2025.
//

import Foundation
import Combine

struct UIOWaterUsage: Identifiable {
    let id: UUID
    let date: String
    let dailyUsage: Int
    let overnightUsages: Int
    let overNightLeak: Bool
}

class WaterUsageViewModel: ObservableObject {
    
    @Published var list: [UIOWaterUsage] = []
    
#warning("Meter ID is hardcoded. Replace with dynamic input.")
    @Published var meterId: Int = 1111
    private let waterUsageUseCase: WaterUsageUseCase
    
    private lazy var dateFormater: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    init(waterUsageUseCase: WaterUsageUseCase) {
        self.waterUsageUseCase = waterUsageUseCase
    }
    
    func fetchRequest() {
        let list = self.waterUsageUseCase.execute(id: self.meterId)
        self.list = mapData(list: list)
    }
    
}

extension WaterUsageViewModel {
    
    func mapData(list: [WaterUsageResult]) -> [UIOWaterUsage] {
        return list.map { UIOWaterUsage(id: UUID(),
                                        date: dateFormater.string(from: $0.date),
                                        dailyUsage: $0.dailyUsage,
                                        overnightUsages: $0.overnightUsages,
                                        overNightLeak: $0.overNightLeak) }
    }
    
}
