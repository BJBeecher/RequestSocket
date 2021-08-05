//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/18/21.
//

import Foundation

public enum RSFailure : Error {
    case encoding(Error)
    case decoding(Error)
    case listenerError(Error)
    case pingError(Error)
    case messageError(Error)
    case notConnected
    case timeout
}
