//
//  WaterUsageRepository.swift
//  Levno-4Aug
//
//  Created by Hardeep Singh on 04/08/2025.
//

import Foundation

enum AppError: Error {
    case networkError
    case jsonSerializationError
}

class WaterUsageRepositoryImp: WaterUsageRepostiroy {
    
    let apiService: HTTPClient
    
    init(apiService: HTTPClient = WaterUsageAPI()) {
        self.apiService = apiService
    }
    
    func fetchWaterUsage(id: MeterId) throws -> [WaterUsage] {
        do {
            let list = try apiService.get()
                .toBOModel()
            return list
        } catch {
            throw AppError.networkError
        }
    }
    
}


extension WaterUsage {
    init(dl: DLWaterUsage) {
        self.date = Date(timeIntervalSince1970: TimeInterval(dl.ts))
        self.value = dl.val
    }
}

extension Array where Element == DLWaterUsage {
    func toBOModel() -> [WaterUsage] {
        return self.map { WaterUsage(dl: $0) }
    }
}
