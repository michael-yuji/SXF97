# SXF97

SXF97 is a building block for writing HTTP-based application using [spartanX](https://github.com/michael-yuji/spartanX).

# Usage 

SXF97 support the following features:
 * Normal HTTP service
 * Upgrade to another service (response a HTTP response, than switch to different service for the connection)
 * Switch to another service (switch the service used for the connection to another service directly)

SXF97 only defines building blocks for http service. Therefore, as any spartanX service, we need a server socket and a Kernel to run. See [spartanX Readme Document](https://github.com/projectSX0/spartanX) for more details.

A very simple HTTP service will be:

```swift
let service = HTTPService { (request, connection) throws -> HTTPResponse? in   
        return HTTPResponse(status: 200, text: "Hello World")
    }

guard let server = try? SXServerSocket.tcpIpv4(service: service, port: 8080) else {
    print("cannot create server socket")
    exit(1)
}

SXKernelManager.initializeDefault()
SXKernelManager.default!.manage(server, setup: nil)
dispatchMain()
```

## HTTPS

To Create a HTTPS service is almost identical to HTTP but you will need an additional TLS Layer, you will need to add [SXTLS](https://github.com/projectSX0/SXTLS) module to your project, see the [readme file of SXTLS](https://github.com/projectSX0/SXTLS) for more info.

## Switching/Upgrading to different protocol

The following defines a service that upgrade/switch to another http service depends on the uri

Any further payload from the switched/upgraded connection will handle by the new service directly.

This feature is extremely useful for implement websocket or other non-http protocols that initiate with http payload.

```swift
// main.swift
import Foundation
import SXF97
import spartanX

let service2 = HTTPService { (request, connection) -> HTTPResponse? in
    return HTTPResponse(status: 200, text: "You received message from this service")
}

let service = HTTPService { (request, connection) throws -> HTTPResponse? in
    
    // in both cases, any futher payload will send to service2 directly after switch/upgrade
    if request.uri.path == "/test/upgrade" {
        // the first argument is the service switch to, the second one is the response 
        // we are going to send to client, in this case, a text response to the client
        // notify them to refresh the page to see the new message
        throw HTTPException.upgradeService(service2, HTTPResponse(status: 200, text: "upgrading to service2, refresh your browser"))
    } else if request.uri.path == "/test/switch" {
        // the first argument is the service switch to, the second one is the the initial payload 
        // to service2, in this case, we redirect the request to service2,
        // and for the client it is same as they made a request to service2 directly.
        throw HTTPException.switchService(service2, request.raw)
    }
    return HTTPResponse(status: 200, text: "Hello World")
}

guard let server = try? SXServerSocket.tcpIpv4(service: service, port: 8080) else {
    print("cannot create server socket")
    exit(1)
}

SXKernelManager.initializeDefault()
SXKernelManager.default!.manage(server, setup: nil)

dispatchMain()

```

