//
//  SolarManagerError.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 29.09.2024.
//

public class SolarManagerError: Error {
    public let message: String
    
    public init(_ message: String) {
        self.message = message
    }
}
