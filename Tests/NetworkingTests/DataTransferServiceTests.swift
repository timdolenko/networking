@testable import Networking
import XCTest

// MARK: - MockModel

private struct MockModel: Decodable {
    let name: String
}

// MARK: - DataTransferServiceTests

class DataTransferServiceTests: XCTestCase {
    // MARK: Internal

    func test_whenReceivedValidJsonInResponse_shouldDecodeObject() {
        // given
        let expectation = self.expectation(description: "Should decode mock object")
        
        let name = "Alex"
        
        let responseData =
            """
            { "name": "\(name)" }
            """
            .data(using: .utf8)
        
        let networkService = makeNetworkService(with: responseData)
        
        let sut = DataTransferServiceLive(networkService: networkService)
        // when
        _ = sut.request(with: mockModelEndpoint, completion: { result in
            
            switch result {
            case let .success(object):
                XCTAssertEqual(object.name, name)
                expectation.fulfill()
            case .failure:
                XCTFail("Should not happen")
            }
        })
        
        // then
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_whenReceivedInvalidJSONInResponse_shouldNotDecodeObject() {
        // given
        let expectation = self.expectation(description: "Should not decode mock object")
        
        let responseData =
            """
            { "age": 20 }
            """
            .data(using: .utf8)
        
        let networkService = makeNetworkService(with: responseData)
        
        let sut = DataTransferServiceLive(networkService: networkService)
        // when
        _ = sut.request(with: mockModelEndpoint, completion: { result in
            
            switch result {
            case .success:
                XCTFail("Should not happen")
            case .failure:
                expectation.fulfill()
            }
        })
        
        // then
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_whenBadRequestReceived_shouldReturnNetworkFailureError() {
        // given
        let expectation = self.expectation(description: "Should return network failure error")
        
        let responseData =
            """
            { "error":"some error" }
            """
            .data(using: .utf8)
        
        let response = makeHTTPResponse(withStatusCode: 500)
        
        let sessionManager = NetworkSessionManagerMock(
            response: response,
            data: responseData,
            error: DataTransferErrorMock.someError
        )
        
        let networkService = NetworkServiceLive(
            config: mockConfig,
            sessionManager: sessionManager
        )
        
        let sut = DataTransferServiceLive(networkService: networkService)
        
        // when
        _ = sut.request(with: mockModelEndpoint, completion: { result in
            
            switch result {
            case .success:
                XCTFail("Should not happen")
            case let .failure(error):
                
                guard case DataTransferError.networkFailure(
                    NetworkError.error(statusCode: 500, data: _)
                ) = error else {
                    XCTFail("Wrong error")
                    return
                }
                
                expectation.fulfill()
            }
        })
        
        // then
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_whenNoDataReceived_shouldThrowNoDataError() {
        // given
        let expectation = self.expectation(description: "Should throw no data error")
        
        let response = makeHTTPResponse(withStatusCode: 200)
        
        let sessionManager = NetworkSessionManagerMock(
            response: response,
            data: nil,
            error: nil
        )
        
        let networkService = NetworkServiceLive(config: mockConfig, sessionManager: sessionManager)
        
        let sut = DataTransferServiceLive(networkService: networkService)
        // when
        _ = sut.request(with: mockModelEndpoint, completion: { result in
            switch result {
            case .success:
                XCTFail("Should not happen")
            case let .failure(error):
                guard case DataTransferError.noResponse = error else {
                    XCTFail("Wrong error")
                    return
                }
                
                expectation.fulfill()
            }
        })
        
        // then
        wait(for: [expectation], timeout: 0.1)
    }

    // MARK: Private

    private enum DataTransferErrorMock: Error { case someError }

    private let mockConfig = NetworkConfigurableMock()
    private let mockModelEndpoint = Endpoint<MockModel>(path: "/mock", method: .get)

    private func makeNetworkService(with data: Data?) -> NetworkServiceLive {
        NetworkServiceLive(
            config: mockConfig,
            sessionManager: NetworkSessionManagerMock(
                response: nil,
                data: data,
                error: nil
            )
        )
    }
    
    private func makeHTTPResponse(withStatusCode statusCode: Int) -> HTTPURLResponse? {
        HTTPURLResponse(
            url: URL(string: "mock")!,
            statusCode: statusCode,
            httpVersion: "1.1",
            headerFields: nil
        )
    }
}
