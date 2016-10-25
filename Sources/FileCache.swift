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

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#else
import Glibc
#endif

import CoreCache
import struct Foundation.UUID
import struct Foundation.Data
public typealias CacheId = String
public typealias SXFileCache = SXCacheManager

public final class SXCacheManager {
    public static var shared = SXCacheManager()
    internal var container = CacheContainer(refreshResulotion: CCTimeInterval(milisec: 100))
    
    public func fdAvailable(path: String) -> Int32? {
        return container.currentFd(of: path)
    }
    
    public func get(cached: String, errHandler: ((String, Error) -> ())? = nil) -> Data? {
        if let data = container[cached] {
            return data
        } else {
            self.container.cacheFile(at: cached, as: cached, using: .lazyUp2Date, lifetime: .idleInterval(CCTimeInterval(sec: 300)), errHandle: errHandler)
            return container[cached]
        }
    }
    
    public func getStaticFile(path: String, errHandler: ((String, Error) -> ())? = nil) -> Int32? {
        if let fd = container.currentFd(of: path) {
            return fd
        } else {
            self.container.cacheFile(at: path, as: path, using: .noReserve, lifetime: .idleInterval(CCTimeInterval(sec: 300)), errHandle: errHandler)
            return container.currentFd(of: path)
        }
    }
}
