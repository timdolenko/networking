import Foundation

// MARK: - NetworkConfigurable

public protocol NetworkConfigurable {
    var baseURL: URL { get }
    var headers: [String: String] { get }
    var queryParameters: [String: String] { get }
}

// MARK: - ApiDataNetworkConfig

public struct ApiDataNetworkConfig: NetworkConfigurable {
    // MARK: Lifecycle

    public init(
        baseURL: URL,
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.headers = headers
        self.queryParameters = queryParameters
    }

    // MARK: Public

    public let baseURL: URL
    public let headers: [String: String]
    public let queryParameters: [String: String]
}
