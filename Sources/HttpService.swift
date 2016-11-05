
//    Copyright (c) 2016, yuuji
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions are met:
//
//    * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//    The views and conclusions contained in the software and documentation are those
//    of the authors and should not be interpreted as representing official policies,
//    either expressed or implied, of the FreeBSD Project.
//

import Foundation
import spartanX

public typealias Exception = Error
public typealias SXConnection = SXQueue

public enum HTTPException: Exception {
    case switchService(SXService, Data)
    case upgradeService(SXService, HTTPResponse)
}

public struct HTTPService {
    
    public var handler: (HTTPRequest, SXConnection) throws -> HTTPResponse?
     public var supportingMethods: SendMethods = [.send, .sendfile]
}

extension HTTPService {
    fileprivate func send(response: HTTPResponse, to connection: SXConnection) {
        _ = try? response.send(with: self.supportingMethods.intersection(connection.supportedMethods), using: connection.writeAgent)
    }
}

extension HTTPService : SXService {

    public func received(data: Data, from connection: SXQueue) throws -> Bool {
        return try autoreleasepool {

            guard let httprequest = try? HTTPRequest(data: data) else {
                return false
            }

            let _response = try autoreleasepool(invoking: { () -> HTTPResponse? in
                return try handler(httprequest, connection)
            })

            if let response = _response {
                send(response: response, to: connection)
            }
            
            return true
        }
    }
    
    public func exceptionRaised(_ exception: Error, on connection: SXQueue) {
        guard let exception = exception as? HTTPException else {
            return
        }
        
        if case let .switchService(service, initialPayload) = exception {
            connection.service = service
            _ = try? service.received(data: initialPayload, from: connection)
            
        }
        
        if case let .upgradeService(service, res) = exception {
            send(response: res, to: connection)
            connection.service = service
        }
    }
    
    
    public init(handler: @escaping (_ request: HTTPRequest, _ queue: SXConnection) throws -> HTTPResponse?) {
        self.handler = handler
    }

    public init(router: SXRouter) {
        self.handler = {
            router.ApiLookup(rq: $0.0, connection: $0.1)
        }
    }
}

