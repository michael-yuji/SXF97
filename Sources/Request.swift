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
import spartanX

public struct HTTPRequest: HTTP {
    public var version: HTTPVersion
    public var type: HTTPTypes = .request
    public var content: Data = Data()
    public var method: HTTPMethod
    public var uri: String
    public var headerFields: [String : [String]] = [:]
    
    public var statusline: String {
        return "\(method.rawValue) \(uri) \(version.stringVal)"
    }
    
    public init(version: HTTPVersion, method: HTTPMethod, resource: String, content: Data? = nil, additionalInfo: [String: [String]] = [:]) {
        self.version = version
        self.method = method
        self.uri = resource
        self.headerFields = additionalInfo
        if let content = content {
            self.content = content
            self.headerFields[HTTPRequestEntry.ContentLength] = ["\(content.count)"]
        }
    }
    
    public init(data: Data) throws {
        
        var dataReader = DataReader(fromData: data)
        #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
        guard let statuslineb = dataReader.nextSegmentOfData(separatedBy: Data.crlf),
            let statusline = String(data: statuslineb, encoding: .utf8)
            else {
                throw HTTPErrors.headerContainsNonStringLiterial
        }
        #else
        var crlf: [UInt8] = [0x0d, 0x0a]
        guard let statuslineb = dataReader.nextSegmentOfData(separatedBy: &crlf),
            let statusline = String(data: statuslineb, encoding: .utf8)
            else {
                throw HTTPErrors.headerContainsNonStringLiterial
        }
        #endif
        
        let statuslineComponents = statusline.components(separatedBy: " ")
        if statuslineComponents.count != 3 { throw HTTPErrors.malformedStatusline }
        
        guard let method = HTTPMethod(rawValue: statuslineComponents[0]),
            let version = HTTPVersion(str: statuslineComponents[2]) else {
            throw HTTPErrors.malformedStatusline
        }
        
        self.uri = statuslineComponents[1]
        self.method = method
        self.version = version
        
        do {
            try parseHeaderFields(dataReader: &dataReader)
        } catch {
            throw error
        }
    }
    
    public var cookies: [String: String] {
        guard let cookieEntries = self.headerFields[HTTPRequestEntry.Cookie] , cookieEntries.count > 0 else {return [:]}
        var ret = [String: String]()
        for cookies in cookieEntries {
            for cookie in cookies.components(separatedBy: "; ") {
                guard let separatorPos = cookies.range(of: "=") else { continue }
                let key = cookie.substring(with: cookie.startIndex..<separatorPos.lowerBound)
                ret[key] = cookie.substring(with: separatorPos.upperBound..<cookie.endIndex)
            }
        }
        return ret
    }
}
