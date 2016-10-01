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
import CKit
import Dispatch

import struct Foundation.Data
import struct Foundation.Date

public final class SXFileCache {
    
    public static var `default`: SXFileCache = SXFileCache()
    
    public enum CachedType {
        case fileDescriptor(Int32)
        case rawData(Data)
        
        public var dataValue: Data? {
            switch self {
            case let .fileDescriptor(fd):
                guard let file_status = try? FileStatus(fd: fd) else {
                    return nil
                }
                var buffer = [UInt8](repeating: 0, count: file_status.size)
                read(fd, &buffer, file_status.size)
                return Data(bytes: buffer)
            case let .rawData(data):
                return data
            }
        }
        
        public var length: Int {
            switch self {
            case let .fileDescriptor(fd):
                guard let file_status = try? FileStatus(fd: fd) else {
                    return 0
                }
                return file_status.size
                
            case let .rawData(data):
                return data.length
            }
        }
    }
    
    private enum CachedTypeInternal {
        case fileDescriptor(Int32)
        case generator(() -> Data)
    }
    
    // realPath : fileDescriptor
    private var cacheMap = [String: CachedType]()
    private var cachedGenerator = [String : () -> Data]()
    
    public func request(for file: String) -> CachedType? {
        guard let cached = cacheMap[file] else {
            let filefd = open(file, O_RDWR)
            if filefd == -1 {
                return nil
            }
            self.cacheMap[file] = .fileDescriptor(filefd)
            return .fileDescriptor(filefd)
        }
        return cached
    }
    
    public func cacheDynamic(as path: String, refreshInterval: Double, expiration: Date?, generator: @escaping () -> Data) {
        self.cachedGenerator[path] = generator
        self.cacheMap[path] = .rawData(generator())
        func nextRefresh() {
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + refreshInterval) {
                if let expiration = expiration {
                    if expiration > Date() {
                        self.cacheMap[path] = nil
                        self.cachedGenerator[path] = nil
                        return
                    }
                }
                guard let gen = self.cachedGenerator[path] else {
                    return
                }
                self.cacheMap[path] = .rawData(gen())
                nextRefresh()
            }
        }
    }

    public func cacheStatic(as path: String, content: Data, expiration: Date?) {
        self.cacheMap[path] = .rawData(content)
        if let expiration = expiration {
            let deltaTimeInterval = expiration.timeIntervalSinceNow
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + deltaTimeInterval, execute: {
                self.cacheMap[path] = nil
            })
        }
    }
    
    public func cacheFile(at path: String, expiration: Date?) {
        let filefd = open(path, O_RDWR)
        self.cacheMap[path] = .fileDescriptor(filefd)
        if let expiration = expiration {
            let deltaTimeInterval = expiration.timeIntervalSinceNow
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + deltaTimeInterval, execute: {
                self.cacheMap[path] = nil
                close(filefd)
            })
        }
    }
    
    public func cacheFileContent(at path: String, expiration: Date?) -> Data? {
        let filefd = open(path, O_RDWR)
        
        guard let filesize = try? FileStatus(fd: filefd).size else {
            return nil
        }
        
        guard let buffer = mmap(nil, filesize, PROT_READ | PROT_WRITE, 0, filefd, 0) else {
            return nil
        }
        
        let data = Data(bytesNoCopy: buffer, count: filesize, deallocator: .unmap)
        
        self.cacheMap[path] = .rawData(data)
        if let expiration = expiration {
            let deltaTimeInterval = expiration.timeIntervalSinceNow
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + deltaTimeInterval, execute: {
                self.cacheMap[path] = nil
            })
        }
        
        return data
    }
    
    public func removeCache(at path: String) {
        self.cacheMap[path] = nil
        self.cachedGenerator[path] = nil
    }
    
}


























