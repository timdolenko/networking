@testable import Networking
import XCTest

class EndpointTests: XCTestCase {
    // MARK: Internal

    func test_whenRequestWithBody_shouldAddContentTypeHeader() {
        // given
        let sut = Endpoint<Void>(path: "/test", method: .post)
        sut.bodyParameters = [
            "mock": "data"
        ]
        // when
        guard let request = try? sut.urlRequest(with: mockConfig) else {
            XCTFail("Should not happen")
            return
        }
        
        // then
        let contentTypeHeader = request.value(forHTTPHeaderField: "Content-Type")
        
        XCTAssertEqual(contentTypeHeader, "application/json")
    }
    
    func test_whenRequestWithQueryParameters_shouldAddQueryParameters() {
        // given
        let sut = Endpoint<Void>(path: "/test", method: .get)
        sut.queryParameters = ["key1": "value2"]
        
        let config = mockConfig
        config.queryParameters = ["key1": "value1", "key2": "value3"]
        
        // when
        guard let request = try? sut.urlRequest(with: mockConfig), let url = request.url else {
            XCTFail("Should not happen")
            return
        }
        
        let components = URLComponents(string: url.absoluteString)
        
        guard let items = components?.queryItems else {
            XCTFail("Should not happen")
            return
        }
        
        XCTAssertTrue(items.contains(URLQueryItem(name: "key1", value: "value2")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "key2", value: "value3")))
    }

    // MARK: Private

    private let mockConfig = NetworkConfigurableMock()
}
