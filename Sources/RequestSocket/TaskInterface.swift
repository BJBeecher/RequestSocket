//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/18/21.
//

import Foundation
import Combine

protocol TaskInterface {
    func startListener(delegate: WebsocketDelegateInterface)
    func startPinger(delegate: WebsocketDelegateInterface, interval: TimeInterval)
    func send(_ data: Data) -> AnyPublisher<Void, Error>
}

// conformance

extension URLSessionWebSocketTask : TaskInterface {
    func startListener(delegate: WebsocketDelegateInterface){
        recieveData { [weak self] result in
            switch result {
            
            case .success(let data):
                defer { self?.startListener(delegate: delegate) }
                delegate.task(didRecieveData: data)
                
            case .failure(let error):
                delegate.task(didDisconnect: RSFailure.listenerError(error))
            }
        }
    }
    
    func startPinger(delegate: WebsocketDelegateInterface, interval: TimeInterval = 10){
        sendPing { [weak self] error in
            if let error = error {
                delegate.task(didDisconnect: RSFailure.pingError(error))
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + interval){
                    self?.startPinger(delegate: delegate, interval: interval)
                }
            }
        }
    }
    
    func send(_ data: Data) -> AnyPublisher<Void, Error> {
        Deferred { () -> Future<Void, Error> in
            Future { promise in
                self.send(.data(data)) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
}
