//
//  ApiRouter.swift
//  SXF97
//
//  Created by yuuji on 11/2/16.
//
//

import class spartanX.SXConnection

public struct SXRouter {
    var dict = [String: (HTTPRequest, SXConnection) throws -> HTTPResponse?]()
    
    public mutating func register(path: String, for handler: @escaping (HTTPRequest, SXConnection) throws -> HTTPResponse?) {
        dict[path] = handler
    }
    
    public func ApiLookup(rq: HTTPRequest, connection: SXConnection) throws -> HTTPResponse? {
        guard let api = dict[rq.uri.path] else {
            return nil
        }
        
        return try api(rq, connection)
    }
}
