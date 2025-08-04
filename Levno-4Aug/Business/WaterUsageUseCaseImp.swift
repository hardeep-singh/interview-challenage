//
//  WaterUsageUseCase.swift
//  Levno-4Aug
//
//  Created by Hardeep Singh on 04/08/2025.
//

import Foundation

struct WaterUsage {
    let value: Int
    let date: Date
}

class WaterUsageUseCaseImp: WaterUsageUseCase {
    
    let leakThresholdDailyUsageRatio: Double = 0.05
    let leakThresholdOvernightUsageMultiplier: Double = 2.0
    
    private let calendar = Calendar(identifier: .gregorian)
    let respository: WaterUsageRepostiroy
    init(respository: WaterUsageRepostiroy = WaterUsageRepositoryImp()) {
        self.respository = respository
    }
    
    func execute(id: MeterId) -> [WaterUsageResult] {
        let waterUsageList = (try? respository.fetchWaterUsage(id: id)) ?? []
        return calculateDailyTotalUsage(waterUsage: waterUsageList)
    }
    
    private func calculateDailyTotalUsage(waterUsage: [WaterUsage]) -> [WaterUsageResult] {
        
        var waterUsageList = waterUsage
        waterUsageList.sort { $0.date > $1.date }
        
        let (dailyBasis, overNightBasis) = calculateDailyAndOvernightUsage(from: waterUsageList)
        
        let daysKeys = dailyBasis.keys.sorted { $0 > $1 }
        let avgDaily = Double(dailyBasis.values.reduce(0, +)) / Double(dailyBasis.count)
        let avgOverNight = Double(overNightBasis.values.reduce(0, +)) / Double(overNightBasis.count)
        
        var list: [WaterUsageResult] = []
        for day in daysKeys {
            let usage: Int = dailyBasis[day] ?? 0
            let overnightValue: Int = overNightBasis[day] ?? 0
            
            let leak = Double(overnightValue) > leakThresholdDailyUsageRatio * avgDaily && Double(overnightValue) > leakThresholdOvernightUsageMultiplier * avgOverNight
            let waterUsage: WaterUsageResult = WaterUsageResult(date: day, dailyUsage: usage, overnightUsages: overnightValue, overNightLeak: leak)
            list.append(waterUsage)
        }
        return list
    }
    
    private func calculateDailyAndOvernightUsage(from waterUsageList: [WaterUsage]) -> (dailyUsage: [Date: Int], overnightUsage: [Date: Int]) {
    
        var overNightUsageOnDailyBasis = [Date: Int]()
        var dailyBasis = [Date: Int]()
        
        for water in waterUsageList {
            let startOfDay = getStartOfTheDay(date: water.date)
            if isOverNightUsage(date: water.date) {
                overNightUsageOnDailyBasis[startOfDay, default: 0] += water.value
            }
            dailyBasis[startOfDay, default: 0] += water.value
        }
        return (dailyBasis, overNightUsageOnDailyBasis)
    }
    
    private func isOverNightUsage(date: Date) -> Bool {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else {
            return false
        }
        if hour >= 23 {
            return true
        } else if hour < 3 || (hour == 3 && minute == 0) {
            return true
        }
        return false
    }
    
    private func getStartOfTheDay(date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }
    
}
