//
//  ApiRouter.swift
//  SXF97
//
//  Created by yuuji on 11/2/16.
//
//


public struct SXRouter {
    var dict = [String: (HTTPRequest, SXConnection) -> HTTPResponse?]()
    
    public mutating func register(path: String, for handler: @escaping (HTTPRequest, SXConnection) -> HTTPResponse?) {
        dict[path] = handler
    }
    
    public func ApiLookup(rq: HTTPRequest, connection: SXConnection) -> HTTPResponse? {
        guard let api = dict[rq.uri.path] else {
            return nil
        }
        
        return api(rq, connection)
    }
}
