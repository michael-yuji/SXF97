
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

public struct SXHTTPServer : SXRuntimeDataDelegate {
    
    var server: SXStreamServer!
    
    public static let defaultBacklogSize = 500
    public static let defaultMaxGuestSize = 500
    
    public var didReceiveData: (object: SXQueue, data: Data) -> Bool
    public var didReceiveError: ((object: SXRuntimeObject, err: Error) -> ())?
    var shouldAcceptConnection: ((String) -> Bool)?
    
    var handler: (HTTPRequest, String) -> HTTPResponse? {
        willSet {
            self.didReceiveData = { (object: SXQueue, data: Data) -> Bool in
                guard let httprequest = try? HTTPRequest(data: data) else { return false }
                let queue = (object as! SXStreamQueue)
                if let response = newValue(httprequest, queue.socket.address?.ipaddress ?? "") {
                    try! queue.socket.send(data: response.raw, flags: 0)
                    return true
                } else {
                    return false
                }
            }
        }
    }
}

public extension SXHTTPServer {
    
    public func start() {
        self.server.start()
    }
    
    public func kill() {
        self.server.close()
    }
    
    public init?(port: Int, backlog: Int = SXHTTPServer.defaultBacklogSize, maxGuest: Int = SXHTTPServer.defaultMaxGuestSize, handler: (request: HTTPRequest, fromIP: String) -> HTTPResponse?) {
        self.handler = handler
        
        self.didReceiveData = { (object: SXQueue, data: Data) -> Bool in
            guard let httprequest = try? HTTPRequest(data: data) else { return false }
            let queue = (object as! SXStreamQueue)
            
            if let response = handler(request: httprequest, fromIP: queue.socket.address?.ipaddress ?? "") {
                try! queue.socket.send(data: response.raw, flags: 0)
                return true
            } else {
                return false
            }
        }
        
        self.server = try! SXStreamServer(port: in_port_t(port), domain: .inet, maxGuest: maxGuest, backlog: backlog, dataDelegate: self)
        if self.server == nil {
            return nil
        }
    }
}
