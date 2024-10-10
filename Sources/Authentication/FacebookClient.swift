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
        public let token: String
    }

    enum Error: Swift.Error {
        case noResult
        case cancelled
        case noToken
    }
}

extension FacebookClient {
    public static let live: Self = {
        typealias Subject = PassthroughSubject<Credentials, Swift.Error>
        let loginManager = LoginManager()

        return .init() { permissions in
            let subject = Subject()

//            loginManager.logIn(configuration: .init(permissions: ["user_profile", "email"], tracking: .limited) {

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
                    
                   // AuthenticationToken.
                    
                    subject.send(.init(token: tokenString))
                    subject.send(completion: .finished)

                }
            }
    
//            loginManager.logIn(
//                permissions: permissions,
//                from: (UIApplication.shared.connectedScenes.first! as! UIWindowScene).windows.first!.rootViewController
//            ) { result, error in
//                if let error {
//                    subject.send(completion: .failure(error))
//                    return
//                }
//
//                guard let result else {
//                    subject.send(completion: .failure(Error.noResult))
//                    return
//                }
//
//                if result.isCancelled {
//                    subject.send(completion: .failure(Error.cancelled))
//                    return
//                }
//
//                guard let token = result.token else {
//                    subject.send(completion: .failure(Error.noToken))
//                    return
//                }
//
//                subject.send(.init(token: token.tokenString))
//                subject.send(completion: .finished)
//            }

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
