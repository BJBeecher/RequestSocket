//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/18/21.
//

import Foundation

enum Failure : Error {
    case encoding
    case decoding
    case listenerError(Error)
    case pingError(Error)
    case messageError(Error)
    case notConnected
    case timeout
}
