//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/3/21.
//

import Foundation
import Combine

struct WSRequest<Payload: Encodable> : Encodable {
    let id = UUID()
    let payload : Payload
}

extension WSRequest {
    func encode(with encoder: JSONEncoder) -> AnyPublisher<Data, Error> {
        do {
            let data = try encoder.encode(self)
            return Just(data)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
}
