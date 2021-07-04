//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/3/21.
//

import Foundation
import Combine

// conformance

public final class Websocket : NSObject, ObservableObject {
    
    let url : URL
    
    let encoder : JSONEncoder
    let decoder : JSONDecoder
    
    public init(url: URL, encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
        self.url = url
        self.encoder = encoder
        self.decoder = decoder
    }
    
    @Published var connectionStatus : Status = .closed(error: nil)
    
    let requestSubject = PassthroughSubject<(requestId: UUID, data: Data), Error>()
}

// public API

public extension Websocket {
    func connect(withConfiguration config: URLSessionConfiguration) -> AnyPublisher<Bool, Never> {
        Deferred { [self] () -> AnyPublisher<Bool, Never> in
            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            let task = session.webSocketTask(with: url)
            task.resume()
            
            return $connectionStatus
                .map(\.isConnected)
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
    
    func send<Payload: Encodable, Output: Decodable>(payload: Payload, withTimeout timeout: DispatchQueue.SchedulerTimeType.Stride? = 8) -> AnyPublisher<Output, Error> {
        let request = WSRequest(payload: payload)
        
        guard let data = try? encoder.encode(request) else {
            return Fail(error: Failure.encoding).eraseToAnyPublisher()
        }
        
        return Deferred { [self] () -> AnyPublisher<Output, Error> in
            if case .opened(let task) = self.connectionStatus {
                return task.send(data)
                    .flatMap { requestPublisher(requestId: request.id, timeout: timeout) }
                    .eraseToAnyPublisher()
            } else {
                return Fail(error: Failure.notConnected).eraseToAnyPublisher()
            }
        }.eraseToAnyPublisher()
    }
}

// internal API

extension Websocket {
    func requestPublisher<Output: Decodable>(requestId: UUID, timeout: DispatchQueue.SchedulerTimeType.Stride?) -> AnyPublisher<Output, Error> {
        if let to = timeout {
            return requestSubject
                .first { $0.requestId == requestId }
                .timeout(to, scheduler: DispatchQueue.main)
                .map(\.data)
                .decode(type: WSResponse<Output>.self, decoder: decoder)
                .map(\.payload)
                .eraseToAnyPublisher()
        } else {
            return requestSubject
                .filter { $0.requestId == requestId }
                .map(\.data)
                .decode(type: WSResponse<Output>.self, decoder: decoder)
                .map(\.payload)
                .eraseToAnyPublisher()
        }
    }
}

// foundation delegate conformance

extension Websocket : URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?){
        webSocketTask.startListener(delegate: self)
        webSocketTask.startPinger(delegate: self)
        connectionStatus = .opened(socket: webSocketTask)
    }
}
