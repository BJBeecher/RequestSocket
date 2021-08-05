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
    func task(didRecieveData data: Data)
    func task(didDisconnect error: RSFailure)
}
