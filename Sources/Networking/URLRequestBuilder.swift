import Foundation

// MARK: - ContentType

public enum ContentType {
    case json
    case formUrlEncoded
    case custom(URLRequestContentSetter)

    // MARK: Internal

    var description: String {
        switch self {
        case .json:
            return "application/json"
        case .formUrlEncoded:
            return "application/x-www-form-urlencoded"
        case .custom:
            fatalError("not intended for use")
        }
    }
}

// MARK: - URLRequestContentSetter

public struct URLRequestContentSetter {
    // MARK: Lifecycle

    public init(set: @escaping (inout URLRequest, [String: Any]) throws -> Void) {
        self.set = set
    }

    // MARK: Public

    public let set: (inout URLRequest, [String: Any]) throws -> Void
}

// MARK: - URLRequestBuilderAssembly

public struct URLRequestBuilderAssembly {
    // MARK: Lifecycle

    public init(urlBuilder: URLBuilder = .base, urlRequestBuilder: URLRequestBuilder = .base) {
        self.urlBuilder = urlBuilder
        self.urlRequestBuilder = urlRequestBuilder
    }

    // MARK: Public

    public func urlRequest(with requestable: Requestable, config: NetworkConfigurable) throws -> URLRequest {
        try urlRequestBuilder.urlRequest(urlBuilder, requestable, config)
    }

    // MARK: Private

    private var urlBuilder: URLBuilder
    private var urlRequestBuilder: URLRequestBuilder
}

// MARK: - URLBuilder

public struct URLBuilder {
    // MARK: Lifecycle

    public init(url: @escaping (Requestable, NetworkConfigurable) throws -> URL) {
        self.url = url
    }

    // MARK: Public

    public static var base: URLBuilder {
        .init { request, config -> URL in
            let queryItems = { (config: NetworkConfigurable) -> [URLQueryItem]? in
                var queryItems = config.queryParameters
                request.queryParameters.forEach { queryItems[$0] = $1 }
                
                guard !queryItems.isEmpty else { return nil }
                return queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
            }
            
            let baseURL = config.baseURL.basePath
            
            guard var components = URLComponents(string: baseURL) else {
                throw RequestGenerationError.components
            }
            
            if !components.path.isEmpty {
                components.path.dropLastSlash()
            }
            
            components.path += request.path
            
            components.queryItems = queryItems(config)
            
            guard let url = components.url else { throw RequestGenerationError.components }
            
            return url
        }
    }

    public var url: (Requestable, NetworkConfigurable) throws -> URL
}

// MARK: - URLRequestBuilder

public struct URLRequestBuilder {
    // MARK: Lifecycle

    public init(urlRequest: @escaping (URLBuilder, Requestable, NetworkConfigurable) throws -> URLRequest) {
        self.urlRequest = urlRequest
    }

    // MARK: Public

    public static var base: URLRequestBuilder {
        .init { urlBuilder, request, config -> URLRequest in
            let url = try urlBuilder.url(request, config)
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = request.method.string
            
            for (header, value) in config.headers {
                urlRequest.setValue(value, forHTTPHeaderField: header)
            }
            
            for (header, value) in request.headers {
                urlRequest.setValue(value, forHTTPHeaderField: header)
            }
            
            try urlRequest.addContent(type: request.contentType, body: request.bodyParameters)
            
            return urlRequest
        }
    }

    public var urlRequest: (URLBuilder, Requestable, NetworkConfigurable) throws -> URLRequest
}

// MARK: - RequestGenerationError

enum RequestGenerationError: Error {
    case components
}

extension URL {
    var basePath: String {
        absoluteString.last != "/" ? absoluteString + "/" : absoluteString
    }
}

extension URLRequest {
    mutating func addContent(type: ContentType, body: Encodable?) throws {
        guard let dictionary = try? body?.toDictionary() else { return }
        
        switch type {
        case .json:
            setJSONContent(dictionary)
            
        case .formUrlEncoded:
            setFormUrlEncodedContent(dictionary)
            
        case let .custom(contentSetter):
            try contentSetter.set(&self, dictionary)
        }
    }
    
    private mutating func setJSONContent(_ dictionary: [String: Any]) {
        setContentType(.json)
        setAccept(.json)
        
        httpBody = try? JSONSerialization.data(withJSONObject: dictionary)
    }
    
    private mutating func setFormUrlEncodedContent(_ dictionary: [String: Any]) {
        setContentType(.formUrlEncoded)
        
        httpBody = dictionary
            .reduce("") { "\($0)\($1.0)=\($1.1)&" }
            .dropLast()
            .data(using: .utf8, allowLossyConversion: false)
    }
    
    private mutating func setContentType(_ type: ContentType) {
        setValue(type.description, forHTTPHeaderField: "Content-Type")
    }
    
    private mutating func setAccept(_ type: ContentType) {
        setValue(type.description, forHTTPHeaderField: "Accept")
    }
}

extension String {
    mutating func dropLastSlash() {
        guard last == "/" else { return }
        self = String(dropLast())
    }
}

private extension Encodable {
    func toDictionary() throws -> [String: Any]? {
        let data = try JSONEncoder().encode(self)
        let jsonData = try JSONSerialization.jsonObject(with: data)
        return jsonData as? [String: Any]
    }
}
