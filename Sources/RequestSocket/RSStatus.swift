//
//  File.swift
//  
//
//  Created by BJ Beecher on 2/12/21.
//

import Foundation

enum RSStatus {
    case connecting
    case opened(socket: TaskInterface)
    case closed(error: Error? = nil)
}

extension RSStatus {
    var isConnected : Bool {
        switch self {
            case .opened: return true
            default: return false
        }
    }
}
