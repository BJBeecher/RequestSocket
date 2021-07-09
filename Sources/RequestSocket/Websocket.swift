//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/3/21.
//

import Foundation
import Combine

// conformance

public final class Websocket {
    
    let encoder : JSONEncoder
    let decoder : JSONDecoder
    
    let delegate : WebsocketDelegateInterface
    let sessionType : SessionInterface.Type
    
    init(encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init(), delegate: WebsocketDelegateInterface, sessionType: SessionInterface.Type) {
        self.encoder = encoder
        self.decoder = decoder
        self.delegate = delegate
        self.sessionType = sessionType
    }
    
    public convenience init(encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
        self.init(encoder: encoder, decoder: decoder, delegate: WebsocketDelegate(decoder: decoder), sessionType: URLSession.self)
    }
}

// public API

public extension Websocket {
    func connect(withRequest request: URLRequest) -> AnyPublisher<Bool, Never> {
        Deferred { [self] () -> AnyPublisher<Bool, Never> in
            let session = sessionType.init(configuration: .default, delegate: delegate, delegateQueue: nil)
            session.startWebsocket(with: request)
            
            return delegate.connectionSubject
                .map(\.isConnected)
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
    
    func send<Payload: Encodable, Output: Decodable>(payload: Payload, withTimeout timeout: DispatchQueue.SchedulerTimeType.Stride? = 8) -> AnyPublisher<Output, Error> {
        let request = WSRequest(payload: payload)
        
        guard let data = try? encoder.encode(request) else {
            fatalError()
            return Fail(error: Failure.encoding).eraseToAnyPublisher()
        }
        
        guard case .opened(let task) = self.delegate.connectionStatus else {
            fatalError()
            return Fail(error: Failure.notConnected).eraseToAnyPublisher()
        }
        
        return task.send(data)
            .flatMap { [self] _ -> AnyPublisher<Output, Error> in
                if let to = timeout {
                    return timeoutPublisher(requestId: request.id, timeout: to)
                } else {
                    return continuousPublisher(requestId: request.id)
                }
            }
            .eraseToAnyPublisher()
    }
}

// internal API

extension Websocket {
    func timeoutPublisher<Output: Decodable>(requestId: UUID, timeout: DispatchQueue.SchedulerTimeType.Stride) -> AnyPublisher<Output, Error> {
        delegate.requestSubject
            .first { $0.requestId == requestId }
            .timeout(timeout, scheduler: DispatchQueue.main)
            .map(\.data)
            .decode(type: WSResponse<Output>.self, decoder: decoder)
            .map(\.payload)
            .eraseToAnyPublisher()
    }
    
    func continuousPublisher<Output: Decodable>(requestId: UUID) -> AnyPublisher<Output, Error> {
        delegate.requestSubject
            .filter { $0.requestId == requestId }
            .map(\.data)
            .decode(type: WSResponse<Output>.self, decoder: decoder)
            .map(\.payload)
            .eraseToAnyPublisher()
    }
}
