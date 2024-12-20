//
//  SolarManagerApiClientError.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 12.10.2024.
//

enum SolarManagerApiClientError: Error {
    case invalidArguments
    case communicationError
    case errorWhileEncoding
    case errorWhileDecoding
}
