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

public enum HTTPRoles {
    case request
    case response
}

public protocol HTTP {
    var version: HTTPVersion {get}
    var type: HTTPRoles {get}
    var content: Data? {get set}
    var contentSource: ContentSource? {get set}
    var statusline: String {get}
    var headerFields: [String: [String]] {get set}
}

extension HTTP {
    public var sendOptions: SendMethods {
        return [.send, .sendfile]
    }
    
    public func send(with method: SendMethods, using socket: Writable) throws {
        try socket.write(data: raw)
    }
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
    
    public mutating func appendHeader(field: String, val: String) {
        if let _ = self.headerFields[field] {
            self.headerFields[field]?.append(val)
        } else {
            self.headerFields[field] = [val]
        }
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
        if let content = content {
            data!.append(content)
        }
        return data!
    }
    
    public var rawHeader: Data {
        var data = headerFields.reduce("\(statusline)\r\n", {"\($0)\(expandHeader(key: $1.key, value: $1.value))"}).data(using: .utf8)
        data!.append(Data.crlf)
        return data!
    }
    
    mutating func parseHeaderFields(ignoreContent: Bool, dataReader: inout DataReader) throws {
        
        var line = ""
        
        repeat {

            guard let lineb = dataReader.nextSegmentOfData(separatedBy: Data.crlf),
                let line_ = String(data: lineb, encoding: .utf8) else {
                    throw HTTPErrors.headerContainsNonStringLiterial
            }
            
            line = line_
            
            if line.isEmpty {
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
            
        } while !line.isEmpty

        if !ignoreContent {
            content = dataReader.origin.subdata(in: dataReader.origin.index(0, offsetBy: dataReader.currentOffset)..<dataReader.origin.endIndex)
        }
    }
}
