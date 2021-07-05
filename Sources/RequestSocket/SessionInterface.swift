//
//  File.swift
//  
//
//  Created by BJ Beecher on 7/4/21.
//

import Foundation

protocol SessionInterface {
    var delegate : URLSessionDelegate? { get }
    
    init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?)
    
    func startWebsocket(with request: URLRequest)
}

// default conformance

extension URLSession : SessionInterface {
    func startWebsocket(with request: URLRequest) {
        let task = webSocketTask(with: request)
        task.resume()
    }
}
