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

public struct CommonCookieAttributes {
    static let httpOnly = ["HttpOnly": ""]
    static let secure = ["Secure": ""]
    public struct Keys {
        public let expires = "Expires"
        public let path = "Path"
        public let domain = "Domain"
    }
}

public struct Cookie: CustomStringConvertible {
    public var key: String
    public var val: String
    public var attributes: [String: String]
    public init(key: String, val: String, attributes: [String: String] = [:]) {
        self.key = key
        self.val = val
        self.attributes = attributes
    }
    
    public var description: String {
        return self.attributes.reduce("\(key)=\(val)") {"\($0); \(attributeToString($1))"}
    }
    
    private func attributeToString(_ attribute: (key: String, value: String)) -> String {
        if val == "" { return key }
        return "\(key)=\(val)"
    }
}

public struct HTTPResponse: HTTP {
    public var content: Data = Data()
    public var version: HTTPVersion
    public var type = HTTPTypes.response
    public var headerFields: [String: [String]] = [:]
    public var status: HTTPStatus
    
    public var cookies: [Cookie] = [] {
        didSet {
            headerFields[HTTPResponseEntry.SetCookie] = cookies.map {$0.description}
        }
    }
    
}

public extension HTTPResponse {
    
    public var statusline: String {
        return "\(version.stringVal) \(status.raw) \(status.description)"
    }
    
    public init(httpVersion version: HTTPVersion = HTTPVersion.default, status: HTTPStatus, entries: [String : [String]] = [:], with payload: Data?) {
        self.status = status
        self.headerFields = entries
        self.content = payload ?? Data()
        self.version = version
        if content.count > 0 {
            self.headerFields[HTTPResponseEntry.ContentLength] = ["\(content.count)"]
        }
    }
    
    public init(httpVersion version: HTTPVersion = HTTPVersion.default, status: HTTPStatus, entries: [String: [String]] = [:], text payload: String?) {
        self.status = status
        self.headerFields = entries
        self.content = payload == nil ? Data() : payload?.data(using: .utf8) ?? Data()
        self.version = version
        if content.count > 0 {
            self.headerFields[HTTPResponseEntry.ContentLength] = ["\(content.count)"]
        }
    }
    
    public init(httpVersion version: HTTPVersion = HTTPVersion.default, status: Int, entries: [String : [String]] = [:], with payload: Data?) {
        self.status = HTTPStatus(raw: status)!
        self.headerFields = entries
        self.content = payload ?? Data()
        self.version = version
        if content.count > 0 {
            self.headerFields[HTTPResponseEntry.ContentLength] = ["\(content.count)"]
            if content.isGzipped {
                self.headerFields[HTTPResponseEntry.TransferEncoding] = ["gzip"]
            }
        }
    }
    
    public init(httpVersion version: HTTPVersion = HTTPVersion.default, status: Int, entries: [String: [String]] = [:], text payload: String?) {
        self.status = HTTPStatus(raw: status)!
        self.headerFields = entries
        self.content = payload == nil ? Data() : payload?.data(using: .utf8) ?? Data()
        self.version = version
        if content.count > 0 {
            self.headerFields[HTTPResponseEntry.ContentLength] = ["\(content.count)"]
        }
    }
    
    public init(data: Data) throws {
        
        var dataReader = DataReader(fromData: data)
        
        var httplinebreak: [UInt8] = [0xd, 0xa]
        
        guard let statuslineb = dataReader.nextSegmentOfData(separatedBy: &httplinebreak),
            let statusline = String(data: statuslineb, encoding: .utf8)
            else {
                throw HTTPErrors.headerContainsNonStringLiterial
        }
        
        let statuslineComponents = statusline.components(separatedBy: " ")
        if statuslineComponents.count != 3 { throw HTTPErrors.malformedStatusline }
        
        guard let code = Int(statuslineComponents[1]),
            let status = HTTPStatus(raw: code),
            let version = HTTPVersion(str: statuslineComponents[0])
            else {
                throw HTTPErrors.malformedEntry
        }
        
        self.status = status
        self.version = version
        
        do {
            try parseHeaderFields(ignoreContent: false, dataReader: &dataReader)
        } catch {
            throw error
        }
    }
}
