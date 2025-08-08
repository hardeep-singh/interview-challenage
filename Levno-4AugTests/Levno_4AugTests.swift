//
//  Levno_4AugTests.swift
//  Levno-4AugTests
//
//  Created by Hardeep Singh on 04/08/2025.
//

import XCTest
@testable import Levno_4Aug

final class Levno_4AugTests: XCTestCase {
    
    let METER_ID = 1234
    func test_StartDateAndEndDate() {
        let (sut, _) = makeSUT(mockData: [])
        _ = sut.execute(id: METER_ID)
    }

    func test_execute_ReturnEmptyList_ForLast20Days() {
        let expectedItems = [MockDayData].createEmptyList()
        
        let (sut, _) = makeSUT(mockData: expectedItems)
        let receivedItems = sut.execute(id: METER_ID)
        
        XCTAssertEqual(receivedItems.count, 0)
    }
    
    func test_execute_returnDayUsageOnly_ForLast20Days() {
        // Given Data
        var expectedItems = [MockDayData].createEmptyList()
        expectedItems.addDayUsageOnly()
        
        let (sut, client) = makeSUT(mockData: expectedItems)
        let receivedItems = sut.execute(id: METER_ID)
        
        expect(expectedItems, client: client, receivedItems: receivedItems)
    }
    
    func test_execute_returnNightUsageOnly_12AMT03AM_forLast20Days() {
        var expectedItems = [MockDayData].createEmptyList()
        expectedItems.overnightaddOvernightUsageMidnightTo3AM()
        
        let (sut, client) = makeSUT(mockData: expectedItems)
        let receivedItems = sut.execute(id: METER_ID)
        
        expect(expectedItems, client: client, receivedItems: receivedItems)
    }
    
    func test_execute_returnNightUsageOnly_11PMto12AM_ForLast20Days() {
        var expectedItems = [MockDayData].createEmptyList()
        expectedItems.addOvernightUsageAt11PM()
        
        let (sut, client) = makeSUT(mockData: expectedItems)
        let receivedItems = sut.execute(id: METER_ID)
        
        expect(expectedItems, client: client, receivedItems: receivedItems)
    }
    
    func test_execute_returnDailyUsageAndovernightUsage() {
        var expectedItems = [MockDayData].createEmptyList()
        expectedItems.addDayUsageOnly()
        expectedItems.overnightaddOvernightUsageMidnightTo3AM()
        expectedItems.addOvernightUsageAt11PM()
        
        let (sut, client) = makeSUT(mockData: expectedItems)
        let receivedItems = sut.execute(id: METER_ID)
        
        expect(expectedItems, client: client, receivedItems: receivedItems)
    }

    func test_execute_ReturnsLeakWhenEnoughData() {
        for i in 0..<6 {
            var expectedItems = [MockDayData].createEmptyList()
            expectedItems.addDayUsageOnly()
            expectedItems.overnightaddOvernightUsageMidnightTo3AM()
            expectedItems.addOvernightLeak(dayOffset: i)

            let (sut, client) = makeSUT(mockData: expectedItems)
            let receivedItems = sut.execute(id: METER_ID)
            
            expect(expectedItems, client: client, receivedItems: receivedItems)
        }
    }
    
    func testExecuteReturnsNoLeakWhenInsufficientData() {
        for i in 7..<19 {
            var expectedItems = [MockDayData].createEmptyList()
            expectedItems.addDayUsageOnly()
            expectedItems.addOvernightLeak(dayOffset: i)
            
            let (sut, client) = makeSUT(mockData: expectedItems)
            let receivedItems = sut.execute(id: METER_ID)
            
            XCTAssertNil(receivedItems.first(where: { $0.overnightLeak }))
            XCTAssertEqual(client.analytics.messages.count, 14)

            let skippedMsgs = client.analytics.messages
                .compactMap { $0["UsageUseCase"] }
                .filter { $0.contains("Leak check skipped — not enough data") }
                .count
            XCTAssertEqual(client.analytics.messages.count, skippedMsgs, "Found unexpected analytics messages")
        }
    }
    
    func expect(_ expectedItems: [MockDayData], client: (repository: MockWaterUsageRepository, analytics: MockAnalyticsClient), receivedItems: [WaterUsageResult]) {
        XCTAssertEqual(client.repository.meterId, [METER_ID])
        XCTAssertEqual(expectedItems.count, receivedItems.count, "Expected \(expectedItems.count) items, but received \(receivedItems.count).")
        for (index, expectedItem) in expectedItems.enumerated() {
            let dayComponents = calendar.dateComponents([.day,.month,.year], from: expectedItem.dayDate)
            let dayString = "\(dayComponents.day!)-\(dayComponents.month!)-\(dayComponents.year!)"
            let message = "Day: \(dayString)"
            
            guard let receivedItem = receivedItems.first(where: { isSameDay(date1: expectedItem.dayDate, date2: $0.date) }) else {
                XCTFail("Expected item for \(message) at index \(index), but no matching received item found.")
                continue
            }
            
            XCTAssertEqual(
                expectedItem.dailyUsage,
                receivedItem.dailyUsage,
                "Mismatch at index \(index) on \(message): expected dailyUsage = \(expectedItem.dailyUsage), but received = \(receivedItem.dailyUsage).\n"
            )
            
            XCTAssertEqual(
                expectedItem.overnightUsage,
                receivedItem.overnightUsage,
                "Mismatch at index \(index) on \(message): expected overnightUsage = \(expectedItem.overnightUsage), but received = \(receivedItem.overnightUsage).\n"
            )
            
            XCTAssertEqual(
                expectedItem.overnightLeak,
                receivedItem.overnightLeak,
                "Mismatch at index \(index) on \(message): expected overnightLeak = \(expectedItem.overnightLeak), but received = \(receivedItem.overnightLeak).\n"
            )
        }

    }
    
    func makeSUT(mockData: [MockDayData]) -> (sut: WaterUsageUseCase,client: (repository: MockWaterUsageRepository, analytics: MockAnalyticsClient)) {
        let repository = MockWaterUsageRepository(mockData: mockData)
        let analytics =  MockAnalyticsClient()
        let sut = WaterUsageUseCaseImp(repository: repository, analytics: analytics)
        return (sut, (repository, analytics))
    }
    
}

// MARK: - Data Helper
extension Array where Element == MockDayData {
    
    static func createEmptyList(for days: Int = 20) -> [MockDayData] {
        let list: [MockDayData] = (0..<20).map { index in
            let dayOffset = (index * -1)
            let date = createDate(hour: 0, minute: 0, dayOffset: dayOffset)
            let mockData = MockDayData(dayDate: date, dayOffset: dayOffset)
            return mockData
        }
        return list
    }
    
    mutating func addDayUsageOnly() {
        self = self.map { day in
            var _day = day
            for i in 3..<23 {
                let minute = Int.random(in: 0...58)
                _day.list.append(createEntry(hour: i, minute: minute, value: 100, dayOffset: day.dayOffset))
                _day.dailyUsage += 100
            }
            return _day
        }
    }
    
    mutating func overnightaddOvernightUsageMidnightTo3AM() {
        self = self.map { day in
            var _day = day
            for i in 0..<3 {
                let minute = Int.random(in: 10...58)
                _day.list.append(createEntry(hour: i, minute: minute, value: 10, dayOffset: day.dayOffset))
                _day.overnightUsage += 10
                _day.dailyUsage += 10
            }
            return _day
        }
    }
    
    mutating func addOvernightUsageAt11PM() {
        for i in stride(from: self.count-1, through: 0, by: -1) {
            let day = self[i]
            let minute = Int.random(in: 10...58)
            let entry = createEntry(hour: 23, minute: minute, value: 10, dayOffset: day.dayOffset)
            self[i].list.append(entry)
            self[i].dailyUsage += 10
            if i != 0 {
                self[i-1].overnightUsage += 10
            }
        }
    }
    
    mutating func addOvernightLeak(dayOffset: Int = 0) {
        var day = self[dayOffset]
        let leakageValue = (self[dayOffset+1].overnightUsage * 2) + 150
        let entry = createEntry(hour: 2, minute: 8, value: leakageValue, dayOffset: day.dayOffset)
        day.list.append(entry)
        day.dailyUsage += leakageValue
        day.overnightUsage += leakageValue
        day.overnightLeak = true
        self[dayOffset] = day
    }
    
}

struct MockDayData {
    
    let dayOffset: Int
    let dayDate: Date
    var dailyUsage: Int = 0
    var overnightUsage: Int = 0
    var overnightLeak: Bool = false
    var list = [WaterUsage]()
    
    init(dayDate: Date, dayOffset: Int) {
        self.dayDate = dayDate
        self.dayOffset = dayOffset
    }
}

func isSameDay(date1: Date , date2: Date) -> Bool {
    return calendar.isDate(date1, equalTo: date2, toGranularity: .day)
}

private func createEntry(hour: Int, minute: Int = 0, value: Int, dayOffset: Int = 0) -> WaterUsage {
    let shiftedDate = createDate(hour: hour, minute: minute, dayOffset: dayOffset)
    return WaterUsage(value: value, date: shiftedDate)
}

private func createDate(hour: Int, minute: Int, dayOffset: Int) -> Date {
    let baseDate = Date()
    var dateComponents = calendar.dateComponents(in: .current, from: baseDate)
    dateComponents.day = 4
    dateComponents.month = 8
    dateComponents.year = 2025
    dateComponents.timeZone = .current
    dateComponents.hour = hour
    dateComponents.minute = minute
    dateComponents.second = 0
    let targetDate = calendar.date(from: dateComponents)!
    let shiftedDate = calendar.date(byAdding: .day, value: dayOffset, to: targetDate)!
    return shiftedDate
}

var calendar: Calendar = {
    var calendar = Calendar.current
    calendar.timeZone = .current
    return calendar
}()

// MARK: - Mock respository
class MockWaterUsageRepository: WaterUsageRepository {
    let mockData: [MockDayData]
    private(set) var meterId: [Int] = []
    
    init(mockData: [MockDayData]) {
        self.mockData = mockData
    }
    
    func fetchWaterUsage(id: MeterId) -> [WaterUsage] {
        self.meterId.append(id)
        return mockData.flatMap { $0.list }
    }
}

class MockAnalyticsClient: AppAnalytics {
    private(set) var messages: [[String : String]] = []
    func track(_ message: [String : String]) {
         messages.append(message)
    }
}
