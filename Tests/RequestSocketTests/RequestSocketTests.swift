    import XCTest
    import Combine
    @testable import RequestSocket
    
    final class RequestSocketTests: XCTestCase {
        var tokens = Set<AnyCancellable>()
        
        func testContinuousPub(){
            // given
            let websocket = Websocket()
            let payload = UUID()
            let response = WSResponse(requestId: UUID(), payload: payload)
            let requestId = response.requestId
            let data = try! JSONEncoder().encode(response)
            let expectation = self.expectation(description: "output")
            
            var output : UUID?
            
            // when
            websocket.continuousPublisher(requestId: requestId)
                .sink { completion in
                    switch completion {
                    case .finished:
                        fatalError()
                    case .failure(let error):
                        print(error)
                    }
                } receiveValue: { (thing: UUID) in
                    output = thing
                    
                    expectation.fulfill()
                }.store(in: &tokens)
            
            websocket.delegate.requestSubject.send((requestId: requestId, data: data))
            
            waitForExpectations(timeout: 5, handler: nil)
            
            XCTAssertEqual(payload, output)
        }
        
        func testTimoutPub(){
            // given
            let websocket = Websocket()
            let payload = UUID()
            let response = WSResponse(requestId: UUID(), payload: payload)
            let requestId = response.requestId
            let data = try! JSONEncoder().encode(response)
            let expectation = self.expectation(description: "output")
            
            var output : UUID?
            
            // when
            websocket.timeoutPublisher(requestId: requestId, timeout: 8)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("finished")
                    case .failure(let error):
                        print(error)
                    }
                } receiveValue: { (thing: UUID) in
                    output = thing
                    
                    expectation.fulfill()
                }.store(in: &tokens)
            
            websocket.delegate.requestSubject.send((requestId: requestId, data: data))
            
            waitForExpectations(timeout: 5, handler: nil)
            
            XCTAssertEqual(payload, output)
        }
    }
