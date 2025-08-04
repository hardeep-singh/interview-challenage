//
//  Levno_4AugTests.swift
//  Levno-4AugTests
//
//  Created by Hardeep Singh on 04/08/2025.
//

import XCTest
@testable import Levno_4Aug

final class Levno_4AugTests: XCTestCase {
    
    func test_StartDateAndEndDate() {
        let expectedMeterId = 111
        let (sut, client) = makeSUT(items: [])
        _ = sut.execute(id: expectedMeterId)
        XCTAssertEqual(client.meterId, [expectedMeterId])
    }
    
    func test_execute_ReturnOverNightLeak() {
        var items: [WaterUsage] = []
        for day in 0..<10 {
            let isLeakDay = day == 9
            items.append(createEntry(hour: 13, value: 1000, dayOffset: day))
            items.append(createEntry(hour: 1, value: isLeakDay ? 300 : 10, dayOffset: day))
        }
        let (sut, _) = makeSUT(items: items)
        let results = sut.execute(id: 111)
        let leakDays = results.filter { $0.overNightLeak }
        XCTAssertEqual(leakDays.count, 1)
        XCTAssertTrue(leakDays[0].overNightLeak)
    }
    
    func test_execute_sortsResultsByDateDescending() {
        let meterID = 111
        let items = makeItemsForLast15Days()
        let (sut, client) = makeSUT(items: items)
        let results = sut.execute(id: meterID)
        
        XCTAssertEqual(client.meterId, [111])
        XCTAssertEqual(results.count, 15)
        let firstDate = results.first!.date
        let lastDate = results.last!.date
        XCTAssertTrue(firstDate > lastDate, "First Date: \(firstDate) Last Date: \(lastDate)")
    }
    
    func test_execute_ReturnSingleDayWaterUsage() {
        let items = [createEntry(hour: 10, value: 100, dayOffset: 0),
                     createEntry(hour: 12, value: 200, dayOffset: 0),
                     createEntry(hour: 14, value: 300, dayOffset: 0)]
        let (sut, _) = makeSUT(items: items)
        let results = sut.execute(id: 111)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].dailyUsage, 600)
    }
    
    func test_execute_ReturnMoreThanOneDaysWaterUsage() {
        let items = [createEntry(hour: 10, value: 100, dayOffset: 0),
                     createEntry(hour: 11, value: 100, dayOffset: 0),
                     createEntry(hour: 12, value: 105, dayOffset: -2),
                     createEntry(hour: 14, value: 115, dayOffset: -1),
                     createEntry(hour: 14, value: 101, dayOffset: -4),
                     createEntry(hour: 14, value: 102, dayOffset: -3)]
        
        let (sut, _) = makeSUT(items: items)
        let results = sut.execute(id: 111)
        
        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(results[0].dailyUsage, 200)
        XCTAssertEqual(results[1].dailyUsage, 115)
        XCTAssertEqual(results[2].dailyUsage, 105)
        XCTAssertEqual(results[3].dailyUsage, 102)
        XCTAssertEqual(results[4].dailyUsage, 101)
    }
    
    func test_execute_returnsEmptyList_whenRepositoryReturnsEmpty() {
        
        let meterID = 111
        let (sut, client) = makeSUT(items: [])
        let results = sut.execute(id: meterID)
        
        XCTAssertEqual(client.meterId, [meterID])
        XCTAssertEqual(results.count, 0)
    }
    
    func test_execute_ReturnsLast15DaysWaterUsage() {
        let items = makeItemsForLast15Days()
        let (sut, _) = makeSUT(items: items)
        let results = sut.execute(id: 111)
        
        XCTAssertEqual(results.count, 15)
        for i in 0..<15 {
            XCTAssertEqual(results[i].dailyUsage, 1025)
            XCTAssertEqual(results[i].overnightUsages, 20)
        }
        
    }
    
    func test_execute_returnsLeakIfAboveThreshold() {
        let items = makeItemsForLast15Days(waterLeak: .aboveDailyAverage(5))
        let (sut, _) = makeSUT(items: items)
        let results = sut.execute(id: 111)
        
        XCTAssertEqual(results.count, 15)
        for i in 0..<15 {
            if i == 5 {
                XCTAssertEqual(results[i].dailyUsage, 1057)
                XCTAssertEqual(results[i].overnightUsages, 52)
                XCTAssertTrue(results[5].overNightLeak)
            } else {
                XCTAssertEqual(results[i].dailyUsage, 1025)
                XCTAssertEqual(results[i].overnightUsages, 20)
                XCTAssertFalse(results[i].overNightLeak)
            }
        }
        
    }
    
    func test_execute_nightUsageExceedsAverageNightUsage() {
        let items = makeItemsForLast15Days(waterLeak: .aboveNigthAverage(5))
        let (sut, _) = makeSUT(items: items)
        let results = sut.execute(id: 111)
        
        XCTAssertEqual(results.count, 15)
        for i in 0..<15 {
            if i == 5 {
                XCTAssertEqual(results[i].dailyUsage, 1050)
                XCTAssertEqual(results[i].overnightUsages, 45)
                XCTAssertFalse(results[i].overNightLeak)
            } else {
                XCTAssertEqual(results[i].dailyUsage, 1025)
                XCTAssertEqual(results[i].overnightUsages, 20)
                XCTAssertFalse(results[i].overNightLeak)
            }
        }
        
    }
    
    func makeSUT(items: [WaterUsage]) -> (sut: WaterUsageUseCase, client: MockWatherUsageRepostiroy) {
        let repository = MockWatherUsageRepostiroy(items: items)
        let sut = WaterUsageUseCaseImp(respository: repository)
        return (sut, repository)
    }
    
}

func buildItemOnDayBasis( list: inout [WaterUsage], index: Int, waterLeak: WaterLeakIf) {
    let day = (index * -1)
    list.append(createEntry(hour: 08, value: 500, dayOffset: day))
    list.append(createEntry(hour: 18, value: 500, dayOffset: day))
    switch waterLeak {
    case .aboveDailyAverage(let _index) where _index == index:
        list.append(createEntry(hour: 23, minute: 10, value: 10, dayOffset: day))
        list.append(createEntry(hour: 00, minute: 1, value: 5, dayOffset: day))
        list.append(createEntry(hour: 00, minute: 10, value: 5, dayOffset: day))
        list.append(createEntry(hour: 3, minute: 0, value: 32, dayOffset: day))
    case .aboveNigthAverage(let _index) where _index == index:
        list.append(createEntry(hour: 23, minute: 10, value: 10, dayOffset: day))
        list.append(createEntry(hour: 00, minute: 1, value: 10, dayOffset: day))
        list.append(createEntry(hour: 00, minute: 10, value: 10, dayOffset: day))
        list.append(createEntry(hour: 3, minute: 0, value: 15, dayOffset: day))
    default:
        list.append(createEntry(hour: 23, minute: 10, value: 5, dayOffset: day))
        list.append(createEntry(hour: 00, minute: 1, value: 5, dayOffset: day))
        list.append(createEntry(hour: 00, minute: 10, value: 5, dayOffset: day))
        list.append(createEntry(hour: 3, minute: 0, value: 5, dayOffset: day))
    }
    list.append(createEntry(hour: 3, minute: 1, value: 5, dayOffset: day))
}

enum WaterLeakIf {
    case normalUsage
    case aboveDailyAverage(Int)
    case aboveNigthAverage(Int)
}

func makeItemsForLast15Days(waterLeak: WaterLeakIf = .normalUsage) -> [WaterUsage] {
    var list: [WaterUsage] = []
    for i in 0..<15 {
        buildItemOnDayBasis(list: &list, index: i, waterLeak: waterLeak)
    }
    return list
}

private func createEntry(hour: Int, minute: Int = 0, value: Int, dayOffset: Int = 0) -> WaterUsage {
    let baseDate = Date().addingTimeInterval(-60)
    var dateComponents = Calendar.current.dateComponents(in: .current, from: baseDate)
    dateComponents.hour = hour
    dateComponents.minute = minute
    dateComponents.second = 0
    let targetDate = Calendar.current.date(from: dateComponents)!
    let shiftedDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: targetDate)!
    return WaterUsage(value: value, date: shiftedDate)
}

class MockWatherUsageRepostiroy: WaterUsageRepostiroy {
    
    let items: [WaterUsage]
    private(set) var meterId: [Int] = []
    init(items: [WaterUsage]) {
        self.items = items
    }
    
    func fetchWaterUsage(id: MeterId) -> [WaterUsage] {
        self.meterId.append(id)
        return items
    }
    
}
