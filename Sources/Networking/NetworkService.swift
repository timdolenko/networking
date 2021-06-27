import Foundation

// MARK: - NetworkError

public enum NetworkError: Error {
    case error(statusCode: Int, data: Data?)
    case notConnected
    case cancelled
    case generic(Error)
    case urlGeneration
}

// MARK: - NetworkCancellable

public protocol NetworkCancellable {
    func cancel()
}

// MARK: - URLSessionTask + NetworkCancellable

extension URLSessionTask: NetworkCancellable {}

// MARK: - NetworkService

public protocol NetworkService {
    typealias CompletionHandler = (Result<Data?, NetworkError>) -> Void
    
    func request(endpoint: Requestable, completion: @escaping CompletionHandler) -> NetworkCancellable?
}

// MARK: - NetworkSessionManager

public protocol NetworkSessionManager {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    
    func request(
        _ request: URLRequest,
        completion: @escaping CompletionHandler
    ) -> NetworkCancellable
}

// MARK: - NetworkServiceLive

open class NetworkServiceLive: NetworkService {
    // MARK: Lifecycle

    public init(
        config: NetworkConfigurable,
        sessionManager: NetworkSessionManager = NetworkSessionManagerLive()
    ) {
        self.config = config
        self.sessionManager = sessionManager
    }

    // MARK: Open

    open func request(endpoint: Requestable, completion: @escaping CompletionHandler) -> NetworkCancellable? {
        guard let request = try? endpoint.urlRequest(with: config) else {
            completion(.failure(.urlGeneration))
            return nil
        }
        
        return sessionManager.request(request) { data, response, requestError in
            if let requestError = requestError {
                var error: NetworkError
                if let response = response as? HTTPURLResponse {
                    error = .error(statusCode: response.statusCode, data: data)
                } else {
                    error = self.resolve(error: requestError)
                }
                
                completion(.failure(error))
            } else if let response = response as? HTTPURLResponse, !(200 ... 299).contains(response.statusCode) {
                completion(.failure(.error(statusCode: response.statusCode, data: data)))
            } else {
                completion(.success(data))
            }
        }
    }

    // MARK: Private

    private let config: NetworkConfigurable
    private let sessionManager: NetworkSessionManager

    private func resolve(error: Error) -> NetworkError {
        let code = URLError.Code(rawValue: (error as NSError).code)
        
        switch code {
        case .notConnectedToInternet:
            return .notConnected
        case .cancelled:
            return .cancelled
        default:
            return .generic(error)
        }
    }
}

// MARK: - NetworkSessionManagerLive

public final class NetworkSessionManagerLive: NetworkSessionManager {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func request(_ request: URLRequest, completion: @escaping CompletionHandler) -> NetworkCancellable {
        let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
        task.resume()
        return task
    }
}
