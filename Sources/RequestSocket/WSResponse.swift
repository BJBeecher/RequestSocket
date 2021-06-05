//
//  File.swift
//  
//
//  Created by BJ Beecher on 3/5/21.
//

import Foundation

struct WSResponse<Payload: Decodable> : Decodable {
    let requestId : UUID
    let payload : Payload
}
