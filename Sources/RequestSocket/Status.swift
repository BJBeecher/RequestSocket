//
//  File.swift
//  
//
//  Created by BJ Beecher on 2/12/21.
//

import Foundation

enum Status {
    case opened(socket: WebsocketInterface)
    case closed(error: Error? = nil)
}
