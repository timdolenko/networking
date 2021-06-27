import Combine

public extension DataTransferService {
    @available(iOS 13.0, *)
    @discardableResult
    func request<T: Decodable, E: ResponseRequestable>(
        with endpoint: E
    ) -> AnyPublisher<T, Error> where E.Response == T {
        var task: NetworkCancellable?
        
        return Future() { [unowned self] promise in
            task = request(with: endpoint, completion: { result in
                promise(result)
            })
        }.handleEvents(receiveCancel: {
            task?.cancel()
        }).eraseToAnyPublisher()
    }
}
