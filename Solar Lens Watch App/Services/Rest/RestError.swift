import Foundation

enum RestError: Error {
    case responseError(response: URLResponse)
    case invalidResponseNoData(response: URLResponse)
}
