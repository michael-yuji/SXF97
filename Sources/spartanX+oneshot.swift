//
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


import spartanX
import struct Foundation.Data
import struct FoundationPlus.DataReader

public enum F97ConnectionMode {
    case http
    case https
    case tcp
    case tcpTls
}

public enum F97Response {
    case http(HTTPResponse)
    case error(Error)
    case raw(Data)
}

// for optimization
public enum ContentSource {
    case staticFile(String)
}

public extension SXConnectionSocket {
    
    public static func oneshot<Result>(with mode: F97ConnectionMode, host: String, service: String, request: Data?, handler: (F97Response) -> Result) -> Result {
        do {
            var connectionSocket: SXConnectionSocket!
            
            switch mode {
            case .http, .tcp:
                connectionSocket = try SXConnectionSocket(hostname: host, service: service)
            case .https, .tcpTls:
                connectionSocket = try SXConnectionSocket(tls: true, hostname: host, service: service, type: .stream, protocol: 0)
            }
            
            if let request = request {
                try connectionSocket.write(data: request)
            }
            
            var proceed = false
            
            func readChunked(data: Data) throws -> (Bool, Data) {
                var reader = DataReader(fromData: data)
                let t = data.subdata(in: data.index(data.length, offsetBy: -5)..<data.index(data.length, offsetBy: 0)) == Data(bytes: [0x30, 0x0d, 0x0a, 0x0d, 0x0a])
                
                guard
                    let n_bytes_string_in_binary = reader.nextSegmentOfData(separatedBy: Data.crlf),
                    let n_bytes_string = String(data: n_bytes_string_in_binary, encoding: .ascii),
                    let n_bytes = Int(n_bytes_string, radix: 16) else {
                        throw HTTPErrors.malformedEntry
                }
                
                return (t, data.subdata(in: data.index(reader.currentOffset, offsetBy: 0)..<data.index(reader.currentOffset, offsetBy: n_bytes)))
                
            }
            
            
            let data = try connectionSocket.read()!
            
            if mode == .http || mode == .https {
                var response = try HTTPResponse(data: data)
                if let content = response.content {
                    if response.exist(valueOf: "chunked", inField: HTTPResponseEntry.TransferEncoding)
                        && content.length >= 5 {
                        
                        let chunkedContent = response.content
                        if let data = chunkedContent {
                            var reformedDataPool = try readChunked(data: data)
                            
                            while !reformedDataPool.0 {
                                guard let newPayload = try connectionSocket.read() else {
                                    break
                                }
                                let x = try readChunked(data: newPayload)
                                reformedDataPool.0 = x.0
                                reformedDataPool.1.append(x.1)
                            }
                            response.content = reformedDataPool.1
                        }
                    }
                }
                return handler(.http(response))
            }
            
            return handler(.raw(data))
            
        } catch {
            return handler(.error(error))
        }
    }
}
