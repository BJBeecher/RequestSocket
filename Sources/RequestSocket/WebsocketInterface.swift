//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/18/21.
//

import Foundation

protocol WebsocketInterface {
    func startListener(delegate: WebsocketDelegate)
    func startPinger(delegate: WebsocketDelegate)
    func send(_ data: Data, delegate: WebsocketDelegate)
}

// conformance

extension URLSessionWebSocketTask : WebsocketInterface {
    func startListener(delegate: WebsocketDelegate){
        recieveData { [weak self] result in
            switch result {
            
            case .success(let data):
                defer { self?.startListener(delegate: delegate) }
                delegate.task(didRecieveData: data)
                
            case .failure(let error):
                delegate.task(didDisconnect: Failure.listenerError(error))
            }
        }
    }
    
    func startPinger(delegate: WebsocketDelegate){
        sendPing { [weak self] error in
            if let error = error {
                delegate.task(didDisconnect: Failure.pingError(error))
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5){
                    self?.startPinger(delegate: delegate)
                }
            }
        }
    }
    
    func send(_ data: Data, delegate: WebsocketDelegate){
        send(.data(data)) { error in
            if let error = error {
                delegate.task(didDisconnect: Failure.messageError(error))
            }
        }
    }
}
