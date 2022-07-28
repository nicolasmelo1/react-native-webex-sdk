//
//  Json.swift
//  WebexSDKModule
//
//  Created by Daniel Zarinski on 27/07/22.
//  Copyright © 2022 Launchcode. All rights reserved.
//

import Foundation

class Utils {
    static func toJson<T:Encodable> (value: T?) -> String {
        guard let value = value else {
            return ""
        }
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        
        formatter.dateStyle = .full
        formatter.timeStyle = .full
        
        encoder.dateEncodingStrategy = .formatted(formatter)
        
        if let data = try? encoder.encode(value) {
            return String(data: data, encoding: .utf8)!
        }
        
        return ""
    }
}
