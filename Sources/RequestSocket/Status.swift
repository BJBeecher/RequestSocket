//
//  File.swift
//  
//
//  Created by BJ Beecher on 2/12/21.
//

import Foundation

enum Status {
    case opened(socket: TaskInterface)
    case closed(error: Error? = nil)
}

extension Status {
    var isConnected : Bool {
        switch self {
            case .opened(socket: _):
                return true
            case .closed(error: _):
                return false
        }
    }
}
