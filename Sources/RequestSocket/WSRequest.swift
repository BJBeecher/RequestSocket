//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/3/21.
//

import Foundation

struct WSRequest<Payload: Encodable> : Encodable {
    let id = UUID()
    let payload : Payload
}
