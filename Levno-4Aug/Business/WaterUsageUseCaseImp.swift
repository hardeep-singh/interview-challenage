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
    
    lazy var calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }()
    let repository: WaterUsageRepository
    let analytics: AppAnalytics
    
    init(repository: WaterUsageRepository = WaterUsageRepositoryImp(),analytics: AppAnalytics = AppAnalyticsImp()) {
        self.repository = repository
        self.analytics = analytics
    }
    
    func execute(id: MeterId) -> [WaterUsageResult] {
        let waterUsageList = (try? repository.fetchWaterUsage(id: id)) ?? []
        return calculateDailyTotalUsage(waterUsage: waterUsageList)
    }
    
    private func calculateDailyTotalUsage(waterUsage: [WaterUsage]) -> [WaterUsageResult] {
        
        var waterUsageList = waterUsage
        waterUsageList.sort { $0.date > $1.date }

        let (dailyBasis, overNightBasis) = calculateDailyAndOvernightUsage(from: waterUsageList)
        let sortedDays = dailyBasis.keys.sorted(by: >)

        var results: [WaterUsageResult] = []

        for (index, day) in sortedDays.enumerated() {
            let dailyUsage = dailyBasis[day] ?? 0
            let overNightUsage = overNightBasis[day] ?? 0

            // Slice next 14 days (in sorted order = after current day)
            let next14Days = sortedDays[(index+1)..<min(index+15, sortedDays.count)]
            guard next14Days.count == 14 else {
                results.append(WaterUsageResult(date: day, dailyUsage: dailyUsage, overnightUsage: overNightUsage, overnightLeak: false))
                analytics.track(["UsageUseCase": "Leak check skipped — not enough data"])
                continue
            }

            // Leak detection logic
            let next14OvernightUsages = next14Days.compactMap { overNightBasis[$0] }
            let avgNext14OvernightUsage = Double(next14OvernightUsages.reduce(0, +)) / Double(next14OvernightUsages.count)
            let leak = Double(overNightUsage) > (leakThresholdDailyUsageRatio * Double(dailyUsage)) &&
                       Double(overNightUsage) > (leakThresholdOvernightUsageMultiplier * avgNext14OvernightUsage)
            results.append(WaterUsageResult(date: day, dailyUsage: dailyUsage, overnightUsage: overNightUsage, overnightLeak: leak))
        }

        return results
    }
    
    private func calculateDailyUsage(from waterUsageList: [WaterUsage]) ->  [Date: Int] {
        var dailyUsageCollection = [Date: Int]()
        for water in waterUsageList {
            let startOfDay = getStartOfTheDay(date: water.date)
            dailyUsageCollection[startOfDay, default: 0] += water.value
        }
        return dailyUsageCollection
    }
    
    private func calculateNext14DaysUsage(from waterUsageList: [WaterUsage]) ->  [Date: Int] {
        var overNightUsage = [Date: Int]()
        for water in waterUsageList {
            if let startOfDay = isOverNightUsage(date: water.date) {
                overNightUsage[startOfDay, default: 0] += water.value
            }
        }
        return overNightUsage
    }
    
    private func calculateDailyAndOvernightUsage(from waterUsageList: [WaterUsage]) -> (dailyUsage: [Date: Int], overnightUsage: [Date: Int]) {
        var overNightUsageOnDailyBasis = [Date: Int]()
        var dailyBasis = [Date: Int]()
        
        for water in waterUsageList {
            if let startOfDay = isOverNightUsage(date: water.date) {
                overNightUsageOnDailyBasis[startOfDay, default: 0] += water.value
            }
            let startOfDay = getStartOfTheDay(date: water.date)
            dailyBasis[startOfDay, default: 0] += water.value
        }
        return (dailyBasis, overNightUsageOnDailyBasis)
    }
    
    private func isOverNightUsage(date: Date) -> Date? {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else {
            return nil
        }
        if hour >= 23 {
            let nextDayDate = getNextDay(date: date)
            return getStartOfTheDay(date: nextDayDate)
        } else if hour < 3 {
            return getStartOfTheDay(date: date)
        }
        return nil
    }
    
    private func getNextDay(date: Date) -> Date {
        return calendar.date(byAdding: .day, value: 1, to: date)!
    }
    
    private func getStartOfTheDay(date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }
    
}
