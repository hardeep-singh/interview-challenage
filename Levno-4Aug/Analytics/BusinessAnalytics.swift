//
//  BusinessAnalytics.swift
//  Levno-4Aug
//
//  Created by Hardeep Singh on 08/08/2025.
//

protocol AppAnalytics {
    func track(_ message: [String: String])
}

class AppAnalyticsImp: AppAnalytics {
    
    func track(_ message: [String: String]) {
        // implement analytics service.
        
    }
}
