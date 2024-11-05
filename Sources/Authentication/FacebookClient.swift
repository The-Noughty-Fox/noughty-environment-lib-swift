import Foundation
import FacebookLogin
import FacebookCore
import Combine

public struct FacebookClient {
    public let authenticate: ([String]) -> AnyPublisher<Credentials, Swift.Error>
    public let signOut: () -> Void
    public let handleURL: (URL) -> Bool
}

public extension FacebookClient {
    struct Credentials: Equatable, Codable {
        public let userInfo: UserInfo
    }
    
    enum Error: Swift.Error {
        case noResult
        case cancelled
        case noToken
    }
}

public struct CodableUserAgeRange: Codable, Equatable {
    public let min: Int?
    public let max: Int?
    
    init(from fbAgeRange: UserAgeRange?) {
        self.min = fbAgeRange?.min?.intValue
        self.max = fbAgeRange?.max?.intValue
    }
}

public struct CodableLocation: Codable, Equatable {
    public let id: String?
    public let name: String?
    
    init(from fbLocation: Location?) {
        self.id = fbLocation?.id
        self.name = fbLocation?.name
    }
}

public struct UserInfo: Equatable, Codable {
    public let id: String?
    public let email: String?
    public let friendIDs: [String]?
    public let birthday: Date?
    public let ageRange: CodableUserAgeRange?
    public let gender: String?
    public let location: CodableLocation?
    public let hometown: CodableLocation?
    public let profileURL: URL?
    public let token: String
}

extension FacebookClient {
    public static let live: Self = {
        typealias Subject = PassthroughSubject<Credentials, Swift.Error>
        let loginManager = LoginManager()
        
        return .init() { permissions in
            let subject = Subject()
            
            loginManager.logIn(configuration: .init(permissions: permissions, tracking: .limited, nonce: "2AF72FD0-712D-422D-A5A7-4CEA898A20FE")) { result in
                switch result {
                case .cancelled, .failed:
                    // Handle error
                    print("Facebook auth failed or canceled")
                    subject.send(completion: .failure(Error.cancelled))
                    break
                case .success:
                    // getting user ID
                    let userID = Profile.current?.userID
                    
                    // getting pre-populated email
                    let email = Profile.current?.email
                    
                    // getting pre-populated friends list
                    let friendIDs = Profile.current?.friendIDs
                    
                    // getting pre-populated user birthday
                    let birthday = Profile.current?.birthday
                    
                    // getting pre-populated age range
                    let ageRange = Profile.current?.ageRange
                    
                    // getting user gender
                    let gender = Profile.current?.gender
                    
                    // getting user location
                    let location = Profile.current?.location
                    
                    // getting user hometown
                    let hometown = Profile.current?.hometown
                    
                    // getting user profile URL
                    let profileURL = Profile.current?.linkURL
                    
                    // getting id token string
                    guard let tokenString = AuthenticationToken.current?.tokenString else {
                        subject.send(completion: .failure(Error.noToken))
                        return
                    }
                    
                    let userInfo: UserInfo = .init(
                        id: userID,
                        email: email,
                        friendIDs: friendIDs,
                        birthday: birthday,
                        ageRange: .init(from: ageRange),
                        gender: gender,
                        location: .init(from: location),
                        hometown: .init(from: hometown),
                        profileURL: profileURL,
                        token: tokenString
                    )
                    
                    subject.send(.init(userInfo: userInfo))
                    subject.send(completion: .finished)
                }
            }

            return subject.eraseToAnyPublisher()
        } signOut: {
            loginManager.logOut()
        } handleURL: { url in
            ApplicationDelegate.shared.application(
                UIApplication.shared,
                open: url,
                sourceApplication: nil,
                annotation: [UIApplication.OpenURLOptionsKey.annotation]
            )
        }
    }()
}
