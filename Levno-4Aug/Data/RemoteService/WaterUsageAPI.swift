//
//  WaterUsageAPI.swift
//  Levno-4Aug
//
//  Created by Hardeep Singh on 04/08/2025.
//

import Foundation

protocol HTTPClient {
    func get() throws -> [DLWaterUsage]
}

struct DLWaterUsage: Codable {
    let val: Int
    let ts: Int
}

class WaterUsageAPI: HTTPClient {
   
    func get() throws -> [DLWaterUsage] {
        let jsonData = MOCKAPI.jsonData
        do {
            let list = try JSONDecoder().decode([DLWaterUsage].self, from: jsonData)
            return list
        } catch {
            throw error
        }
    }
    
}

struct MOCKAPI {
    
    static let jsonData = Data(Self.jsonString.utf8)

    static let jsonString = """
    [
        {"ts": 1747916100,"val": 285},
        {"ts": 1747917000,"val": 285},
        {"ts": 1747917900,"val": 1550},
        {"ts": 1747918800,"val": 1400},
        {"ts": 1747919700,"val": 180},
        {"ts": 1747920600,"val": 1165},
        {"ts": 1747921500,"val": 575},
        {"ts": 1747922400,"val": 1210},
        {"ts": 1747923300,"val": 1900},
        {"ts": 1747924200,"val": 0},
        {"ts": 1747925100,"val": 1680},
        {"ts": 1747926000,"val": 125},
        {"ts": 1747926900,"val": 50},
        {"ts": 1747927800,"val": 40},
        {"ts": 1747928700,"val": 5},
        {"ts": 1747929600,"val": 1710},
        {"ts": 1747930500,"val": 1185},
        {"ts": 1747931400,"val": 605},
        {"ts": 1747932300,"val": 1685},
        {"ts": 1747933200,"val": 140},
        {"ts": 1747934100,"val": 965},
        {"ts": 1747935000,"val": 1580},
        {"ts": 1747935900,"val": 285},
        {"ts": 1747936800,"val": 915},
        {"ts": 1747937700,"val": 385},
        {"ts": 1747938600,"val": 610}
    ]
    """
    
}
