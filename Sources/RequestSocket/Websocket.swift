//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/3/21.
//

import Foundation
import Combine

// conformance

public final class Websocket : NSObject {
    let request : URLRequest
    let encoder : JSONEncoder
    let decoder : JSONDecoder
    let Session : SessionInterface.Type
    var connectionStatus = RSStatus.closed(error: nil)
    let requestSubject = PassthroughSubject<(requestId: UUID, data: Data), RSFailure>()
    let connectionSubject = PassthroughSubject<TaskInterface, ConnectionFailure>()
    
    init(
        request: URLRequest,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init(),
        Session: SessionInterface.Type
    ) {
        self.request = request
        self.encoder = encoder
        self.decoder = decoder
        self.Session = Session
    }
    
    public convenience init(
        request: URLRequest,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) {
        self.init(request: request, encoder: encoder, decoder: decoder, Session: URLSession.self)
    }
}

// public API

public extension Websocket {
    func send<Payload: Encodable, Output: Decodable>(
        payload: Payload,
        withTimeout timeout: DispatchQueue.SchedulerTimeType.Stride? = 8,
        withBearerToken token: String? = nil
    ) -> AnyPublisher<Output, Error> {
        let request = WSRequest(payload: payload)
        return request.encode(with: encoder)
            .flatMap { self.mapStatus(requestId: request.id, data: $0, timeout: timeout, token: token) }
            .eraseToAnyPublisher()
    }
}

// internal API

extension Websocket {
    func mapStatus<Output: Decodable>(
        requestId: UUID,
        data: Data,
        timeout: DispatchQueue.SchedulerTimeType.Stride?,
        token: String?
    ) -> AnyPublisher<Output, Error> {
        switch connectionStatus {
            case .connecting:
                return connectionSubject
                    .mapError(RSFailure.connection)
                    .flatMap { task in
                        self.dataTaskPublisher(requestId: requestId, task: task, data: data, timeout: timeout)
                    }
                    .eraseToAnyPublisher()
                
            case .opened(socket: let socket):
                return dataTaskPublisher(requestId: requestId, task: socket, data: data, timeout: timeout)
                
            case .closed:
                return connect(withToken: token)
                    .mapError(RSFailure.connection)
                    .flatMap { task in
                        self.dataTaskPublisher(requestId: requestId, task: task, data: data, timeout: timeout)
                    }
                    .eraseToAnyPublisher()
        }
    }
    
    func connect(withToken token: String?) -> AnyPublisher<TaskInterface, ConnectionFailure> {
        Deferred { [self] () -> AnyPublisher<TaskInterface, ConnectionFailure> in
            connectionStatus = .connecting
            let session = Session.init(configuration: .default, delegate: self, delegateQueue: nil)
            let req = prepareRequest(bearerToken: token)
            session.startWebsocket(with: req)
            
            return connectionSubject.eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
    
    func prepareRequest(bearerToken token: String?) -> URLRequest {
        var req = request
        if let token = token {
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }
    
    func dataTaskPublisher<Output: Decodable>(
        requestId: UUID, task: TaskInterface,
        data: Data,
        timeout: DispatchQueue.SchedulerTimeType.Stride?
    ) -> AnyPublisher<Output, Error> {
        task.send(data)
            .flatMap { [self] _ -> AnyPublisher<Output, Error> in
                if let to = timeout {
                    return timeoutPublisher(requestId: requestId, timeout: to)
                } else {
                    return continuousPublisher(requestId: requestId)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func timeoutPublisher<Output: Decodable>(
        requestId: UUID,
        timeout: DispatchQueue.SchedulerTimeType.Stride
    ) -> AnyPublisher<Output, Error> {
        requestSubject
            .first { $0.requestId == requestId }
            .timeout(timeout, scheduler: DispatchQueue.main)
            .map(\.data)
            .decode(type: WSResponse<Output>.self, decoder: decoder)
            .map(\.payload)
            .eraseToAnyPublisher()
    }
    
    func continuousPublisher<Output: Decodable>(requestId: UUID) -> AnyPublisher<Output, Error> {
        requestSubject
            .filter { $0.requestId == requestId }
            .map(\.data)
            .decode(type: WSResponse<Output>.self, decoder: decoder)
            .map(\.payload)
            .eraseToAnyPublisher()
    }
}

// delegate

extension Websocket : WebsocketDelegateInterface {
    func task(didRecieveData data: Data) {
        do {
            let info = try decoder.decode(WSResponseInfo.self, from: data)
            let tuple = (requestId: info.requestId, data: data)
            requestSubject.send(tuple)
        } catch {
            print(error)
        }
    }
    
    func task(didDisconnect error: RSFailure) {
        connectionStatus = .closed(error: error)
        requestSubject.send(completion: .failure(error))
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        webSocketTask.startListener(delegate: self)
        webSocketTask.startPinger(delegate: self)
        connectionSubject.send(webSocketTask)
        connectionStatus = .opened(socket: webSocketTask)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        connectionSubject.send(completion: .failure(.unknown(error)))
    }
}
