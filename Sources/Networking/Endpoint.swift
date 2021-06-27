import Foundation

// MARK: - HTTPMethodType

public enum HTTPMethodType: String {
    case get
    case post
    case put

    // MARK: Public

    public var string: String {
        rawValue.uppercased()
    }
}

// MARK: - Endpoint

open class Endpoint<R>: ResponseRequestable {
    // MARK: Lifecycle

    public init(
        path: String,
        method: HTTPMethodType,
        bodyParameters: Encodable? = nil,
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:],
        contentType: ContentType = .json,
        responseDecoder: ResponseDecoder = JSONResponseDecoder(),
        requestBuilder: URLRequestBuilderAssembly = .init()
    ) {
        self.path = path
        self.method = method
        self.bodyParameters = bodyParameters
        self.headers = headers
        self.queryParameters = queryParameters
        self.contentType = contentType
        self.responseDecoder = responseDecoder
        self.requestBuilder = requestBuilder
    }

    // MARK: Public

    public typealias Response = R

    public var path: String
    public var method: HTTPMethodType
    public var bodyParameters: Encodable?
    public var headers: [String: String] = [:]
    public var queryParameters: [String: String] = [:]
    public var responseDecoder: ResponseDecoder
    public var contentType: ContentType = .json
    public var requestBuilder: URLRequestBuilderAssembly

    public func urlRequest(with config: NetworkConfigurable) throws -> URLRequest {
        try requestBuilder.urlRequest(with: self, config: config)
    }
}

// MARK: - RequestBody

public protocol RequestBody {}

// MARK: - Requestable

public protocol Requestable {
    var path: String { get }
    var method: HTTPMethodType { get }
    var bodyParameters: Encodable? { get }
    var headers: [String: String] { get }
    var queryParameters: [String: String] { get }
    var contentType: ContentType { get }
    func urlRequest(with config: NetworkConfigurable) throws -> URLRequest
}

// MARK: - ResponseRequestable

public protocol ResponseRequestable: Requestable {
    associatedtype Response
    
    var responseDecoder: ResponseDecoder { get }
}
