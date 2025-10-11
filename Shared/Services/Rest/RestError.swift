internal import Foundation

enum RestError: Error {
    case responseError(response: URLResponse)
    case invalidResponseNoData(response: URLResponse)
    case badRequest(response: URLResponse?, details: String)
}
