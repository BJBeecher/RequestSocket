//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/3/21.
//

import Foundation

struct WSRequest : Encodable {
    let id = UUID()
    let payload : String
}
