//
//  ApiRouter.swift
//  SXF97
//
//  Created by yuuji on 11/2/16.
//
//


public struct SXRouter {
    var dict = [String: (HTTPRequest, String) -> HTTPResponse?]()
    
    public mutating func register(path: String, for handler: @escaping (HTTPRequest, String) -> HTTPResponse?) {
        dict[path] = handler
    }
    
    public func ApiLookup(rq: HTTPRequest, ip: String) -> HTTPResponse? {
        guard let api = dict[rq.uri.path] else {
            return nil
        }
        
        return api(rq, ip)
    }
}
