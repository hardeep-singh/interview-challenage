//
//  WaterUsageRepostiroyInterface.swift
//  Levno-4Aug
//
//  Created by Hardeep Singh on 04/08/2025.
//


protocol WaterUsageRepository {
    
    func fetchWaterUsage(id: MeterId) throws  -> [WaterUsage]
    
}

