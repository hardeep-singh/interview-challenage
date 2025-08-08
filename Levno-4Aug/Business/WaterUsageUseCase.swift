//
//  WaterUsageUseCase.swift
//  Levno-4Aug
//
//  Created by Hardeep Singh on 04/08/2025.
//

import Foundation

public struct WaterUsageResult {
    let date: Date
    let dailyUsage: Int
    let overnightUsage: Int
    let overnightLeak: Bool
}

public typealias MeterId = Int

public protocol WaterUsageUseCase {
    func execute(id: MeterId) -> [WaterUsageResult]
}
