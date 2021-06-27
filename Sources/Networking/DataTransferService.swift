import Foundation

// MARK: - DataTransferError

public enum DataTransferError: Error {
    case noResponse
    case parsing(Error)
    case networkFailure(NetworkError)
}

// MARK: - DataTransferService

public protocol DataTransferService: AnyObject {
    typealias CompletionHandler<T> = (Result<T, Error>) -> Void

    @discardableResult
    func request<T: Decodable, E: ResponseRequestable>(
        with endpoint: E,
        completion: @escaping CompletionHandler<T>
    ) -> NetworkCancellable? where E.Response == T
    
    func request<E: ResponseRequestable>(
        with endpoint: E,
        completion: @escaping (Result<Void, Error>) -> Void
    )
        -> NetworkCancellable? where E.Response == Void
}

// MARK: - ResponseDecoder

public protocol ResponseDecoder {
    func decode<T: Decodable>(_ data: Data) throws -> T
}

// MARK: - DataTransferServiceLive

public final class DataTransferServiceLive {
    // MARK: Lifecycle

    public init(networkService: NetworkService) {
        self.networkService = networkService
    }

    // MARK: Private

    private let networkService: NetworkService
}

// MARK: DataTransferService

extension DataTransferServiceLive: DataTransferService {
    public func request<T: Decodable, E: ResponseRequestable>(
        with endpoint: E,
        completion: @escaping CompletionHandler<T>
    ) -> NetworkCancellable? where E.Response == T {
        networkService.request(endpoint: endpoint) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(data):
                let result: Result<T, Error> = self.decode(data: data, decoder: endpoint.responseDecoder)
                DispatchQueue.main.async { completion(result) }
            case let .failure(error):
                DispatchQueue.main.async {
                    completion(.failure(DataTransferError.networkFailure(error)))
                }
            }
        }
    }
    
    public func request<E: ResponseRequestable>(with endpoint: E, completion: @escaping (Result<Void, Error>) -> Void)
        -> NetworkCancellable? where E.Response == Void
    {
        networkService.request(endpoint: endpoint) { result in
                
            switch result {
            case .success:
                DispatchQueue.main.async { completion(.success(())) }
            case let .failure(error):
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
    
    public func decode<T: Decodable>(data: Data?, decoder: ResponseDecoder) -> Result<T, Error> {
        do {
            guard let data = data else { return .failure(DataTransferError.noResponse) }
            let result: T = try decoder.decode(data)
            return .success(result)
        } catch {
            return .failure(DataTransferError.parsing(error))
        }
    }
}

// MARK: - JSONResponseDecoder

public class JSONResponseDecoder: ResponseDecoder {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func decode<T: Decodable>(_ data: Data) throws -> T {
        try jsonDecoder.decode(T.self, from: data)
    }

    // MARK: Private

    private let jsonDecoder = JSONDecoder()
}
