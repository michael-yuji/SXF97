
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

public struct HTTPService : SXStreamSocketService {
    public var errHandler: ((SXQueue, Error) -> ())?
    public var acceptedHandler: ((inout SXClientSocket) -> ())?
    public var willTerminateHandler: ((SXQueue) -> ())?
    public var didTerminateHandler: ((SXQueue) -> ())?
    public var dataHandler: (SXQueue, Data) throws -> Bool
    public static var supportedMethods: SendMethods = [.send, .sendfile]
    
    public var handler: (HTTPRequest, String) -> HTTPResponse? {
        willSet {
            self.dataHandler = { (queue: SXQueue, data: Data) throws -> Bool in
                
                guard let httprequest = try? HTTPRequest(data: data) else {
                    return false
                }
                
                var address: String? = ""
                if let socket = queue.readAgent as? SXClientSocket {
                    address = socket.address?.ipaddress
                }
                
                if let response = newValue(httprequest, address ?? "") {
                    do {
                    try response.send(with: HTTPService.supportedMethods.intersection(queue.supportedMethods), using: queue.writeAgent)
                    } catch {
                        print(error)
                    }
                }
                
                return true
            }
        }
    }
    
    public init(handler: @escaping (_ request: HTTPRequest, _ ip: String) -> HTTPResponse?) {
        self.handler = handler
        self.dataHandler = { (queue: SXQueue, data: Data) throws -> Bool in
            
            autoreleasepool {
                guard let httprequest = try? HTTPRequest(data: data) else {
                    return false
                }
                
                var address: String? = ""
                if let socket = queue.readAgent as? SXClientSocket {
                    address = socket.address?.ipaddress
                }
                
                let _response = autoreleasepool(invoking: { () -> HTTPResponse? in
                    return handler(httprequest, address ?? "")
                })
                
                if let response = _response {
                    
                    do {
                        try response.send(with: HTTPService.supportedMethods.intersection(queue.supportedMethods), using: queue.writeAgent)
                        
                    } catch {
                        print(error)
                    }
                }
                
                return true
            }
        }
    }
}
