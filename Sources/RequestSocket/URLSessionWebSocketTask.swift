//
//  URLSessionWebSocketTask.swift
//  Luna
//
//  Created by BJ Beecher on 1/26/21.
//  Copyright © 2021 Renaissance Technologies. All rights reserved.
//

import Foundation
import Combine

extension URLSessionWebSocketTask {
    func recieveData(completion: @escaping (Result<Data, Error>) -> Void) {
        receive { result in
            switch result {
            
            case .success(let message):
                switch message {
                
                case .data(let data):
                    completion(.success(data))
                    
                case .string(let string):
                    if let data = string.data(using: .utf8) {
                        completion(.success(data))
                    } else {
                        print("Bad message from server: ", string)
                    }
                    
                @unknown default:
                    fatalError("Unknown message from server")
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
