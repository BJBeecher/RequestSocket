//
//  GQLTaskDelegate.swift
//  Luna
//
//  Created by BJ Beecher on 2/1/21.
//  Copyright © 2021 Renaissance Technologies. All rights reserved.
//

import Foundation

protocol WebsocketDelegate : AnyObject {
    func task(didRecieveData data: Data)
    func task(didDisconnect error: Failure)
}

// conformance

extension Websocket : WebsocketDelegate {
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
}
