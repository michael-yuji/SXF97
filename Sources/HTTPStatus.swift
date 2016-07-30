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

public protocol HTTPStatusProtocol {
    var raw: Int {get}
    var description: String {get}
}

public extension HTTPStatusProtocol where Self : CustomStringConvertible {
    var description: String {
        get {
            return self.description
        }
    }
}

public struct HTTPStatusRepresentation {
    public var status: HTTPStatus
    public var desc: String
}

public enum HTTPStatus : HTTPStatusProtocol, CustomStringConvertible {
    case informational(HTTPStatusInformational)
    case success(HTTPStatusSuccess)
    case redirection(HTTPStatusRedirection)
    case clientError(HTTPStatusClientError)
    case serverError(HTTPStatusServerError)
    case unknown(Int)
    
    public var description: String {
        switch self {
        case .informational(let informational):
            return informational.description
        case .success(let success):
            return success.description
        case .redirection(let redirect):
            return redirect.description
        case .clientError(let client):
            return client.description
        case .serverError(let server):
            return server.description
        case .unknown(let desc):
            return "\(desc)"
        }
    }
    
    public var raw: Int {
        get {
            switch self {
            case .informational(let informational):
                return informational.raw
            case .success(let success):
                return success.raw
            case .redirection(let redirect):
                return redirect.raw
            case .clientError(let client):
                return client.raw
            case .serverError(let server):
                return server.raw
            case .unknown(let raw):
                return raw
            }
        }
    }
    
    public init?(raw: Int) {
        switch raw {
        case 100..<200:
            let info = HTTPStatusInformational(rawValue: raw)
            self = .informational(info == nil ? .other : info!)
        case 200..<300:
            let success = HTTPStatusSuccess(rawValue: raw)
            self = .success(success == nil ? .other : success!)
        case 300..<400:
            let redirect = HTTPStatusRedirection(rawValue: raw)
            self = .redirection(redirect == nil ? .other : redirect!)
        case 400..<500:
            let client = HTTPStatusClientError(rawValue: raw)
            self = .clientError(client == nil ? .other : client!)
        case 500..<600:
            let server = HTTPStatusServerError(rawValue: raw)
            self = .serverError(server == nil ? .other : server!)
        default:
            self = .unknown(raw)
        }
    }
}

public enum HTTPStatusInformational: Int, HTTPStatusProtocol, CustomStringConvertible  {
    case `continue` = 100
    case switchingProtocols = 101
    case processing = 102
    
    public var description: String {
        get {
            switch self {
            case `continue`:
                return "Continue"
            case .switchingProtocols:
                return "Switching Protocol"
            case .processing:
                return "Processing"
            default:
                return "??"
            }
        }
    }
    
    case other
    public var raw: Int {
        get {
            return self.rawValue
        }
    }
}

public enum HTTPStatusSuccess: Int, HTTPStatusProtocol, CustomStringConvertible  {
    case ok = 200
    case created = 201
    case accepted = 202
    case nonAuthoritativeInformation = 203
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    case multiStatus = 207
    case alreadyReported = 208
    case other
    
    public var description: String {
        get {
            switch self {
            case .ok:
                return "OK"
            case .created:
                return "Created"
            case .accepted:
                return "Accepted"
            case .nonAuthoritativeInformation:
                return "Non Authoritative Information"
            case .noContent:
                return "No Content"
            case .resetContent:
                return "Reset Content"
            case .partialContent:
                return "Partial Content"
            case .multiStatus:
                return "Multi Status"
            case .alreadyReported:
                return "Already Reported"
            default:
                return "??"
            }
        }
    }
    
    public var raw: Int {
        get {
            return self.rawValue
        }
    }
}

public enum HTTPStatusRedirection: Int, HTTPStatusProtocol, CustomStringConvertible  {
    case multipleChoices = 300
    case movedPermanently = 301
    case found = 302
    case seeOther = 303
    case notModified = 304
    case useProxy = 305
    case switchProxy = 306
    case temporaryRedirect = 307
    case permanentRedirect = 308
    
    public var description: String {
        get {
            switch self {
            case multipleChoices:
                return "Multiple Choices "
            case .movedPermanently:
                return "Moved Permanently"
            case .found:
                return "Found"
            case .seeOther:
                return "See Other"
            case .notModified:
                return "Not Modified"
            case .useProxy:
                return "Use Proxy"
            case .switchProxy:
                return "Switch Proxy"
            case .temporaryRedirect:
                return "Temporary Redirect"
            case .permanentRedirect:
                return "Permanent Redirect"
            default:
                return "??"
            }
        }
    }
    
    case other
    public var raw: Int {
        get {
            return self.rawValue
        }
    }
}

public enum HTTPStatusClientError: Int, HTTPStatusProtocol, CustomStringConvertible  {
    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case proxyAuthenticationRequired = 407
    case requestTimeout = 408
    case conflict = 409
    case gone = 410
    case lengthRequired = 411
    case preconditionFailed = 412
    case payloadTooLarge = 413
    case uriTooLong = 414
    case unsupportedMediaType = 415
    case rangeNotSatisfiable = 416
    case expectationFailed = 417
    case imaTeapot = 418
    case misdirectedRequest = 419
    case unprocessableEntity = 420
    case locked = 423
    case failedDependency = 424
    case upgradeRequired = 425
    case preconditionRequired = 426
    case tooManyRequests = 429
    case requestHeaderFieldsTooLarge = 431
    case unavailableForLegalReasons = 451
    
    public var description: String {
        get {
            switch self {
            case .badRequest:
                return "Bad Request"
            case .unauthorized:
                return "Unauthorized"
            case .paymentRequired:
                return "Payment Required"
            case .forbidden:
                return "Forbidden"
            case .notFound:
                return "Not Found"
            case .methodNotAllowed:
                return "Method Not Allowed"
            case .notAcceptable:
                return "Not Acceptable"
            case .proxyAuthenticationRequired:
                return "Proxy Authentication Required"
            case .requestTimeout:
                return "Request Timeout"
            case .conflict:
                return "Conflict"
            case .gone:
                return "Gone"
            case .lengthRequired:
                return "Length Required"
            case .preconditionFailed:
                return "Precondition Failed"
            case .payloadTooLarge:
                return "Payload Too Large"
            case .uriTooLong:
                return "URI Too Long"
            case .unsupportedMediaType:
                return "Unsupported Media Type"
            case .rangeNotSatisfiable:
                return "Range Not Satisfiable"
            case .expectationFailed:
                return "Expectation Failed"
            case .imaTeapot:
                return "I am a Teapot~~~"
            case .misdirectedRequest:
                return "Misdirected Request"
            case .unprocessableEntity:
                return "Unprocessable Entity"
            case .locked:
                return "Locked"
            case .failedDependency:
                return "Failed Dependency"
            case .upgradeRequired:
                return "Upgrade Required"
            case .tooManyRequests:
                return "Too Many Requests"
            case .requestHeaderFieldsTooLarge:
                return "RequestHeaderFieldTooLarge"
            case .unavailableForLegalReasons:
                return "Unavailable For Legal Reasons"
            default:
                return "??"
            }
        }
    }
    
    case other
    public var raw: Int {
        get {
            return self.rawValue
        }
    }
}

public enum HTTPStatusServerError: Int, HTTPStatusProtocol, CustomStringConvertible  {
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
    case variantAlsoNegotiates = 506
    case insufficientStorage = 507
    case loopDetected = 508
    case notExtented = 509
    case networkAuthenticationRequired = 510
    case lengthRequired = 511
    
    public var description: String {
        get {
            switch self {
            case .internalServerError:
                return "Internal Server Error"
            case .notImplemented:
                return "Not Implemented"
            case .badGateway:
                return "Bad Gateway"
            case .serviceUnavailable:
                return "Service Unavailable"
            case .gatewayTimeout:
                return "Gateway Timeout"
            case .httpVersionNotSupported:
                return "Http Version Not Supported"
            case .variantAlsoNegotiates:
                return "Variant Also Negotiates"
            case .insufficientStorage:
                return "Insufficient Storage"
            case .loopDetected:
                return "Loop Detected"
            case .notExtented:
                return "Not Extented"
            case .networkAuthenticationRequired:
                return "Network Authentication Required"
            case .lengthRequired:
                return "Length Required"
            default:
                return "??"
            }
        }
    }
    
    case other
    public var raw: Int {
        get {
            return self.rawValue
        }
    }
}
