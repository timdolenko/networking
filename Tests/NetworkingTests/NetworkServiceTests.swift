@testable import Networking
import XCTest

class NetworkServiceTests: XCTestCase {
    // MARK: Internal

    func test_whenMockDataPassed_shouldReturnProperResponse() {
        // given
        let expectation = self.expectation(description: "Should return correct data")
        
        let (expectedResponseData, sessionManager) = makeSessionManagerMockWithValidData()
        
        let sut = NetworkServiceLive(config: mockConfig, sessionManager: sessionManager)
        
        // when
        _ = sut.request(endpoint: mockGetValidEndpoint, completion: { result in
            
            switch result {
            case let .success(data):
                XCTAssertEqual(data, expectedResponseData)
                expectation.fulfill()
            case .failure:
                XCTFail("Should return proper response")
            }
        })
        // then
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_onCancelledError_shouldReturnCancelledError() {
        // given
        let expectation = self.expectation(description: "Should return cancelled error")
        
        let cancelledError = NSError(domain: "network", code: NSURLErrorCancelled, userInfo: nil)
        
        let sessionManager = makeSessionManagerMock(with: cancelledError)
        
        let sut = NetworkServiceLive(config: mockConfig, sessionManager: sessionManager)
        
        // when
        _ = sut.request(endpoint: mockGetValidEndpoint, completion: { result in
            
            switch result {
            case .success:
                XCTFail("Should not happen")
            case let .failure(error):
                guard case NetworkError.cancelled = error else {
                    XCTFail("Should return NetworkError.cancelled error")
                    return
                }
                
                expectation.fulfill()
            }
        })
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_whenMalformedUrlPassed_shouldReturnUrlGenerationError() {
        // given
        let expectation = self.expectation(description: "Should return urlGeneration error")
        
        let (_, sessionManager) = makeSessionManagerMockWithValidData()
        
        let sut = NetworkServiceLive(config: mockConfig, sessionManager: sessionManager)
        
        // when
        _ = sut.request(endpoint: Endpoint<Void>(path: "_+)+()+__?", method: .get), completion: { result in
            
            switch result {
            case .success:
                XCTFail("Should not happen")
            case let .failure(error):
                guard case NetworkError.urlGeneration = error else {
                    XCTFail("Should return url generation error")
                    return
                }
                
                expectation.fulfill()
            }
        })
        // then
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_onNotConnectedToInternetError_shouldReturnNotConnectedError() {
        // given
        let expectation = self.expectation(description: "Should return notConnected error")
        
        let error = NSError(domain: "network", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        
        let sessionManager = makeSessionManagerMock(with: error)
        
        let sut = NetworkServiceLive(config: mockConfig, sessionManager: sessionManager)
        
        // when
        _ = sut.request(endpoint: mockGetValidEndpoint, completion: { result in
            switch result {
            case .success:
                XCTFail("Should not happen")
            case let .failure(error):
                guard case NetworkError.notConnected = error else {
                    XCTFail("Should return notConnected error")
                    return
                }
                
                expectation.fulfill()
            }
        })
        
        // then
        wait(for: [expectation], timeout: 0.1)
    }

    // MARK: Private

    private var mockConfig = NetworkConfigurableMock()
    private var mockGetValidEndpoint = Endpoint<Void>(path: "/mockPath", method: .get)

    private func makeSessionManagerMockWithValidData() -> (data: Data, manager: NetworkSessionManagerMock) {
        let expectedResponseData = "Data".data(using: .utf8)!
        
        let mock = NetworkSessionManagerMock(
            response: nil,
            data: expectedResponseData,
            error: nil
        )
        
        return (data: expectedResponseData, manager: mock)
    }
    
    private func makeSessionManagerMock(with error: NSError) -> NetworkSessionManagerMock {
        NetworkSessionManagerMock(
            response: nil,
            data: nil,
            error: error
        )
    }
}
