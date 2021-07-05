//
//  GQLTaskDelegate.swift
//  Luna
//
//  Created by BJ Beecher on 2/1/21.
//  Copyright © 2021 Renaissance Technologies. All rights reserved.
//

import Foundation
import Combine

protocol WebsocketDelegateInterface : URLSessionWebSocketDelegate {
    var connectionStatus : Status { get }
    
    var connectionSubject : PassthroughSubject<Status, Never> { get }
    var requestSubject : PassthroughSubject<(requestId: UUID, data: Data), Error> { get }
    
    func task(didRecieveData data: Data)
    func task(didDisconnect error: Failure)
}

// conformance

final class WebsocketDelegate : NSObject, WebsocketDelegateInterface {
    let decoder : JSONDecoder
    
    init(decoder: JSONDecoder){
        self.decoder = decoder
    }
    
    private (set) var connectionStatus : Status = .closed(error: nil) {
        willSet {
            connectionSubject.send(newValue)
        }
    }
    
    let connectionSubject = PassthroughSubject<Status, Never>()
    let requestSubject = PassthroughSubject<(requestId: UUID, data: Data), Error>()
}

// API

extension WebsocketDelegate {
    func task(didRecieveData data: Data) {
        do {
            let info = try decoder.decode(WSResponseInfo.self, from: data)
            let tuple = (requestId: info.requestId, data: data)
            requestSubject.send(tuple)
        } catch {
            print(error)
        }
    }
    
    func task(didDisconnect error: Failure) {
        connectionStatus = .closed(error: error)
        requestSubject.send(completion: .failure(error))
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?){
        webSocketTask.startListener(delegate: self)
        webSocketTask.startPinger(delegate: self)
        connectionStatus = .opened(socket: webSocketTask)
    }
}
