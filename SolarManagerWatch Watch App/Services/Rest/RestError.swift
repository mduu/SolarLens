//
//  RestError.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 13.10.2024.
//

import Foundation

enum RestError: Error {
    case responseError(response: URLResponse)
    case invalidResponseNoData(response: URLResponse)
}
