import Foundation
@testable import Networking

// MARK: - NetworkTaskMock

struct NetworkTaskMock: NetworkCancellable {
    func cancel() {}
}

// MARK: - NetworkSessionManagerMock

struct NetworkSessionManagerMock: NetworkSessionManager {
    let response: HTTPURLResponse?
    let data: Data?
    let error: Error?

    func request(_ request: URLRequest, completion: @escaping CompletionHandler) -> NetworkCancellable {
        completion(data, response, error)
        return NetworkTaskMock()
    }
}
