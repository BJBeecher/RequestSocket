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
    
    let url : URL
    let config : URLSessionConfiguration
    
    let encoder : JSONEncoder
    let decoder : JSONDecoder
    
    public init(url: URL, config: URLSessionConfiguration = .default,  encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
        self.url = url
        self.config = config
        self.encoder = encoder
        self.decoder = decoder
    }
    
    var connectionStatus : Status = .closed(error: nil)
    
    var pendingRequests = Set<Data>()
    
    let subject = PassthroughSubject<(requestId: UUID, data: Data), Error>()
}

// public API

public extension Websocket {
    func sendRequest<Object: Encodable>(payload: Object) -> AnyPublisher<Data, Error> {
        let request = WSRequest(payload: payload)
        
        guard let requestData = try? encoder.encode(request) else {
            return Fail(error: Failure.encoding).eraseToAnyPublisher()
        }
        
        let subscription = subject
            .filter { $0.requestId == request.id }
            .map(\.data)
            .eraseToAnyPublisher()
        
        return Deferred { [self] () -> AnyPublisher<Data, Error> in
            if case .opened(let task) = connectionStatus {
                task.send(requestData, delegate: self)
            } else {
                pendingRequests.insert(requestData)
                reconnect()
            }
            
            return subscription
        }.eraseToAnyPublisher()
    }
}

// internal API

extension Websocket {
    func connect(){
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.webSocketTask(with: url)
        task.resume()
    }
    
    func reconnect(retryInterval seconds: TimeInterval = 3){
        guard case .closed(_) = connectionStatus else { return }
        
        connect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds){ [weak self] in
            self?.reconnect(retryInterval: seconds)
        }
    }
}

// foundation delegate conformance

extension Websocket : URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?){
        connectionStatus = .opened(socket: webSocketTask)
        
        webSocketTask.startListener(delegate: self)
        webSocketTask.startPinger(delegate: self)
        
        pendingRequests.forEach { data in
            webSocketTask.send(data, delegate: self)
        }
        
        pendingRequests = Set()
    }
}
