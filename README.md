# Networking

Simple and transparent networking library consisting of 5 files, that you can read and understand.

### Example

Let's say we have 2 networking calls we want to perform on client, /me/profile and /me/saveProfile
Let's describe them.
The base path that goes after the domain name: 
https://domain.com/apiv3 **/me**

```swift
public struct Endpoints {}

public extension Endpoints {
    struct Me {
        public static let base = "/me"
    }
    
    static let me = Me.self
}
```

Actual endpoints, request and response are declared below:

```swift
extension Endpoints.Me {
    static func profile() -> Endpoint<ProfileResponseDTO> {
        Endpoint(
            path: base + "/profile",
            method: .get,
            queryParameters: [:],
            requestBuilder: .loggedIn
        )
    }
    
    static func saveProfile(
        with request: SaveProfileRequestDTO
    ) -> Endpoint<SaveProfileResponseDTO> {
        Endpoint(
            path: base + "/saveProfile",
            method: .post,
            queryParameters: request.queryParameters,
            requestBuilder: .loggedIn
        )
    }
}
```

To describe request and responce objects we use handy ```Codable``` protocol:
```swift
struct SaveProfileRequestDTO: Encodable {
    let firstName: String
    let lastName: String
    let age: String
}
struct SaveProfileResponseDTO: Decodable {
    let success: Bool
}

struct ProfileResponseDTO: Decodable {
    let coins: Int
}
```

Let's create our interactor or repository:
```swift
public final class UserRepository {

    public init(service: DataTransferService) {
        self.service = service
    }
    
    public func profile(
        completion: @escaping (Result<InteractionsWithUserResponseDTO, Error>) -> Void
    ) -> Cancellable? {
        let endpoint = endpoints.profile()

        let networkTask = service.request(with: endpoint, completion: completion)

        return RepositoryTask(networkTask: networkTask)
    }
    
    public func saveProfile(
        _ profile: Profile,
        completion: @escaping (Result<SaveProfileResponseDTO, Error>) -> Void
    ) -> Cancellable? {
        let request = SaveProfileRequestDTO(
            firstName: profile.firstName,
            lastName: profile.lastName,
            age: profile.age.description
        )

        let endpoint = endpoints.saveProfile(with: request)

        let networkTask = service.request(with: endpoint, completion: completion)

        return RepositoryTask(networkTask: networkTask)
    }

    private var endpoints = Endpoints.Me.self

    private let service: DataTransferService
}
```

And finally base setup:
```swift
struct NetworkConfig: NetworkConfigurable {
    var baseURL: URL = URL(string: "https://domain.com/apiv3")
    var headers: [String: String] = [
        "DEFAULT_HEADER": "Value"
    ]
    var queryParameters: [String: String] = [
        "sessionId": "SomeId"
    ]
}

let networkService = NetworkServiceLive(config: NetworkConfig())//You can make your own
let service = DataTransferServiceLive(networkService: networkService)//Same!
```

You can create your own network or data tranfer services, even multiple and make them working together in the decorator pattern.
```swift
public class SpecificLayerNetworkingService: NetworkService {

    private var base: NetworkService

    public init(with base: NetworkService) {
        self.base = base
    }

    public func request(endpoint: Requestable, completion: @escaping CompletionHandler) -> NetworkCancellable? {
        base.request(endpoint: endpoint) { [weak self] result in 
            // do something specific!
        }
    }
}

let service = SpecificLayerNetworkingService(with: networkService)
```

This framework is an extended version of library I found here: https://github.com/kudoleh/iOS-Clean-Architecture-MVVM
