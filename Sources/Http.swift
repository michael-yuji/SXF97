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

import Foundation
import FoundationPlus
import spartanX

public enum HTTPMethod : String {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace = "TRACE"
    case patch = "PATCH"
}

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
                
                if response.exist(valueOf: "chunked", inField: HTTPResponseEntry.TransferEncoding)
                    && response.content.length >= 5 {
                    
                    let chunkedContent = response.content
                    var reformedDataPool = try readChunked(data: chunkedContent)
                    
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
                return handler(.http(response))
            }
            
            return handler(.raw(data))
            
        } catch {
            return handler(.error(error))
        }
    }
}


public enum HTTPTypes {
    case request
    case response
}

public protocol HTTP {
    var version: HTTPVersion {get}
    var type: HTTPTypes {get}
    var content: Data {get set}
    var statusline: String {get}
    var headerFields: [String: [String]] {get set}
}

extension HTTP {
    
    func expandHeader(key: String, value: [String]) -> String {
        return value.reduce("") { "\($0)\(key): \($1)\r\n" }
    }
    
    public func valueOf(entry: String) -> [String]? {
        for (__entry__, val) in self.headerFields {
            if __entry__.caseInsensitiveCompare(entry) == .orderedSame {
                return val
            }
        }
        return nil
    }
    
    public func exist(valueOf val: String, inField field: String) -> Bool {
        guard let vals = valueOf(entry: field) else {
            return false
        }
        
        for aval in vals {
            if aval.caseInsensitiveCompare(val) == .orderedSame {
                return true
            }
        }
        
        return false
    }
    
    public var raw: Data {
        var data = headerFields.reduce("\(statusline)\r\n", {"\($0)\(expandHeader(key: $1.key, value: $1.value))"}).data(using: .utf8)
        data!.append(Data.crlf)
        data!.append(self.content)
        return data!
    }
    
    mutating func parseHeaderFields(dataReader: inout DataReader) throws {
        
        var line = ""
        
        repeat {

            guard let lineb = dataReader.nextSegmentOfData(separatedBy: Data.crlf),
                let line_ = String(data: lineb, encoding: .utf8) else {
                    throw HTTPErrors.headerContainsNonStringLiterial
            }
            
            line = line_
            
            if line == "" {
                break
            }
            
            guard let range = line.range(of: ": " ) else {
                throw HTTPErrors.malformedEntry
            }
            
            let key = line.substring(to: range.lowerBound)
            let val = line.substring(with: range.upperBound..<line.endIndex)
            
            if let _ = headerFields[key] {
                headerFields[key]?.append(val)
            } else {
                headerFields[key] = [val]
            }
            
        } while line != ""

        content = dataReader.origin.subdata(in: dataReader.origin.index(0, offsetBy: dataReader.currentOffset)..<dataReader.origin.endIndex)
    }
}
